import cv2
import numpy as np
import base64
import io
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import JSONResponse
from firebase_admin import credentials, firestore, initialize_app
import face_recognition
import mediapipe as mp

# --- Initialisation Firebase ---
cred = credentials.Certificate(r"C:\Users\wiki\Documents\FLUTTER ET DART\app_gestion_docu\serviceAccountKey.json")

initialize_app(cred)
db = firestore.client()

# --- Init FastAPI ---
app = FastAPI()

# --- Init MediaPipe Hands ---
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=True, max_num_hands=2, min_detection_confidence=0.5)

def decode_base64_image(base64_string):
    """Convertit une image base64 en tableau numpy (OpenCV)."""
    img_data = base64.b64decode(base64_string)
    np_arr = np.frombuffer(img_data, np.uint8)
    return cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

def detect_hand(image):
    """Retourne True si une main levée est détectée."""
    img_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    result = hands.process(img_rgb)
    return result.multi_hand_landmarks is not None

@app.post("/api/verify_face_gesture")
async def verify_face_gesture(uid: str = Form(...), file: UploadFile = File(...)):
    try:
        # --- 1. Récupérer photo profil depuis Firestore ---
        doc_ref = db.collection("users").document(uid).get()
        if not doc_ref.exists:
            return JSONResponse({"success": False, "message": "Utilisateur introuvable."}, status_code=404)

        user_data = doc_ref.to_dict()
        if "photoBase64" not in user_data:
            return JSONResponse({"success": False, "message": "Photo de profil manquante."}, status_code=400)

        ref_image = decode_base64_image(user_data["photoBase64"])
        ref_encoding = face_recognition.face_encodings(ref_image)
        if len(ref_encoding) == 0:
            return JSONResponse({"success": False, "message": "Impossible d'extraire visage profil."}, status_code=400)
        ref_encoding = ref_encoding[0]

        # --- 2. Lire image envoyée ---
        img_bytes = await file.read()
        np_arr = np.frombuffer(img_bytes, np.uint8)
        input_image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        input_encoding = face_recognition.face_encodings(input_image)
        if len(input_encoding) == 0:
            return {"success": False, "faceMatched": False, "handDetected": False, "message": "Aucun visage détecté."}

        input_encoding = input_encoding[0]

        # --- 3. Comparaison visage ---
        results = face_recognition.compare_faces([ref_encoding], input_encoding)
        face_matched = results[0]

        # --- 4. Détection main levée ---
        hand_detected = detect_hand(input_image)

        # --- 5. Retour JSON ---
        return {
            "success": face_matched and hand_detected,
            "faceMatched": face_matched,
            "handDetected": hand_detected,
            "message": "Authentification réussie." if face_matched and hand_detected else "Échec authentification."
        }

    except Exception as e:
        return JSONResponse({"success": False, "message": str(e)}, status_code=500)
