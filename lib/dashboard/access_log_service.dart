import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccessLogService {
  static Future<void> addLog({
    required bool faceRecognized,
    required String gesture,
    required bool accepted,
    String? note,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('access_logs').add({
        'uid': user.uid,
        'faceRecognized': faceRecognized,
        'gesture': gesture,
        'accepted': accepted,
        'note': note,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Erreur enregistrement log: $e");
    }
  }

  static Stream<QuerySnapshot> getUserLogs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('access_logs')
        .where('uid', isEqualTo: user.uid)
        .snapshots();
  }
}
