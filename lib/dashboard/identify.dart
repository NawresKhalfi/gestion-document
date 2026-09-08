import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'document.dart';
import 'package:app_gestion_docu/dashboard/access_log_service.dart';
import 'package:app_gestion_docu/dashboard/notification_service.dart';

class FaceGestureCameraScreen extends StatefulWidget {
  const FaceGestureCameraScreen({super.key});

  @override
  State<FaceGestureCameraScreen> createState() =>
      _FaceGestureCameraScreenState();
}

class _FaceGestureCameraScreenState extends State<FaceGestureCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;

  late final FaceDetector _faceDetector;
  late final PoseDetector _poseDetector;

  bool _isProcessing = false;
  bool _isFaceValidated = false;
  bool _isHandValidated = false;
  int _facesDetected = 0;
  String _statusMessage = 'Scannez votre visage pour commencer.';

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.base,
        mode: PoseDetectionMode.single,
      ),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _statusMessage = 'Aucune caméra disponible.';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
      setState(() {
        _statusMessage = "Impossible d'initialiser la caméra ($e)";
      });
    }
  }

  Future<XFile?> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    try {
      return await _cameraController!.takePicture();
    } catch (e) {
      debugPrint('Capture error: $e');
      return null;
    }
  }

  Future<List<Face>> _detectFaces(XFile xfile) async {
    final inputImage = InputImage.fromFilePath(xfile.path);
    return _faceDetector.processImage(inputImage);
  }

  Future<List<Pose>> _detectPoses(XFile xfile) async {
    final inputImage = InputImage.fromFilePath(xfile.path);
    return _poseDetector.processImage(inputImage);
  }

  /// Demande un code PIN (mot de passe de l'utilisateur)
  /// et revérifie l'identité via Firebase Auth.
  Future<bool> _checkUserPin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _showDialog(
        'Erreur',
        "Utilisateur non connecté, impossible de vérifier le code.",
      );
      return false;
    }

    String enteredPassword = '';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Code PIN'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Entrez votre code / mot de passe',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                enteredPassword = controller.text.trim();
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || enteredPassword.isEmpty) {
      return false;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: enteredPassword,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (_) {
      _showDialog('Code incorrect', 'Mot de passe / code PIN invalide.');
      return false;
    } catch (e) {
      debugPrint('Reauth error: $e');
      _showDialog('Erreur', "Impossible de vérifier le code.");
      return false;
    }
  }

  /// Bouton 1 : analyse du visage + code PIN.
  Future<void> _verifyFace() async {
    final capture = await _captureImage();
    if (capture == null) {
      _showDialog('Erreur', "Impossible de capturer l'image.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyse du visage en cours...';
    });

    try {
      final faces = await _detectFaces(capture);
      if (faces.isEmpty) {
        setState(() {
          _isFaceValidated = false;
          _facesDetected = 0;
          _statusMessage = 'Aucun visage détecté.';
        });

        const message = 'Aucun visage détecté. Réessayez.';
        await AccessLogService.addLog(
          faceRecognized: false,
          gesture: 'Visage absent',
          accepted: false,
          note: message,
        );
        await NotificationService.addNotification(
          title: 'Analyse visage',
          body: message,
        );
        _showDialog('Échec', message);
        return;
      }

      final mainFace = faces.first;
      final smiling = (mainFace.smilingProbability ?? 0) > 0.6;
      final eyesOpen = (mainFace.leftEyeOpenProbability ?? 0) > 0.5 &&
          (mainFace.rightEyeOpenProbability ?? 0) > 0.5;

      final successMessage = smiling
          ? 'Visage reconnu avec un sourire.'
          : 'Visage reconnu. Yeux ${eyesOpen ? "ouverts" : "à ouvrir"} pour le geste.';

      // Demande du code PIN (mot de passe utilisateur)
      final pinOk = await _checkUserPin();
      if (!pinOk) {
        const message =
            'Code PIN / mot de passe incorrect, visage refusé.';
        setState(() {
          _isFaceValidated = false;
          _facesDetected = faces.length;
          _statusMessage = message;
        });
        await AccessLogService.addLog(
          faceRecognized: true,
          gesture: 'Code PIN invalide',
          accepted: false,
          note: message,
        );
        await NotificationService.addNotification(
          title: 'Sécurité',
          body: message,
        );
        _showDialog('Refusé', message);
        return;
      }

      setState(() {
        _isFaceValidated = true;
        _isHandValidated = false;
        _facesDetected = faces.length;
        _statusMessage = successMessage;
      });

      await AccessLogService.addLog(
        faceRecognized: true,
        gesture: smiling ? 'Sourire' : 'Visage neutre',
        accepted: true,
        note: successMessage,
      );
      await NotificationService.addNotification(
        title: 'Analyse visage',
        body: successMessage,
      );

      _showDialog('Succès', successMessage);
    } catch (e) {
      final message = 'Analyse impossible: $e';
      debugPrint('Face detection error: $e');
      await AccessLogService.addLog(
        faceRecognized: false,
        gesture: 'Erreur analyse visage',
        accepted: false,
        note: message,
      );
      await NotificationService.addNotification(
        title: 'Analyse visage',
        body: message,
      );
      _showDialog('Erreur', message);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  bool _handIsRaised(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    const minVerticalGap = 40.0;

    bool isLeftRaised = false;
    bool isRightRaised = false;

    if (leftWrist != null && leftShoulder != null) {
      isLeftRaised = leftWrist.y < (leftShoulder.y - minVerticalGap);
    }
    if (rightWrist != null && rightShoulder != null) {
      isRightRaised = rightWrist.y < (rightShoulder.y - minVerticalGap);
    }

    return isLeftRaised || isRightRaised;
  }

  /// Bouton 2 : main levée → navigation vers DocumentManagementScreen.
  Future<void> _verifyHandAndOpenDocs() async {
    if (!_isFaceValidated) {
      const message = 'Veuillez valider votre visage avant de poursuivre.';
      _showDialog('Action impossible', message);
      return;
    }

    final capture = await _captureImage();
    if (capture == null) {
      _showDialog('Erreur', "Impossible de capturer l'image.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Recherche dune main levée...';
    });

    try {
      final poses = await _detectPoses(capture);
      if (poses.isEmpty) {
        const message = 'Aucune main détectée. Réessayez.';
        await AccessLogService.addLog(
          faceRecognized: true,
          gesture: 'Main non détectée',
          accepted: false,
          note: message,
        );
        await NotificationService.addNotification(
          title: 'Détection main',
          body: message,
        );
        _showDialog('Échec', message);
        return;
      }

      final pose = poses.first;
      if (!_handIsRaised(pose)) {
        const message =
            "Levez clairement la main au-dessus de l'épaule pour continuer.";
        await AccessLogService.addLog(
          faceRecognized: true,
          gesture: 'Main non levée',
          accepted: false,
          note: message,
        );
        await NotificationService.addNotification(
          title: 'Détection main',
          body: message,
        );
        _showDialog('Geste manquant', message);
        return;
      }

      const successMessage = 'Main levée détectée : accès autorisé.';
      await AccessLogService.addLog(
        faceRecognized: true,
        gesture: 'Main levée',
        accepted: true,
        note: successMessage,
      );
      await NotificationService.addNotification(
        title: 'Détection main',
        body: successMessage,
      );
      setState(() {
        _isHandValidated = true;
        _statusMessage = successMessage;
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DocumentManagementScreen(),
        ),
      );
    } catch (e) {
      final message = "Impossible d'analyser la main : $e";
      debugPrint('Gesture detection error: $e');
      await AccessLogService.addLog(
        faceRecognized: true,
        gesture: 'Erreur main levée',
        accepted: false,
        note: message,
      );
      await NotificationService.addNotification(
        title: 'Détection main',
        body: message,
      );
      _showDialog('Erreur', message);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _cameraController?.dispose();
    _initializeCamera();
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détection intelligente'),
        backgroundColor: const Color.fromARGB(255, 255, 198, 10),
        actions: [
          IconButton(
            onPressed: _toggleCamera,
            icon: const Icon(Icons.switch_camera),
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          if (_isProcessing)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.black26,
              ),
            ),
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.black.withOpacity(0.6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (_facesDetected > 0)
                      Text(
                        '$_facesDetected visage(s) détecté(s)',
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.face),
                  label: const Text('Analyse du visage (ML Kit)'),
                  onPressed: _verifyFace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 198, 10),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.pan_tool_alt),
                  label: const Text('Détection main levée'),
                  onPressed: _verifyHandAndOpenDocs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

