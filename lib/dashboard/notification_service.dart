import 'package:cloud_firestore/cloud_firestore.dart';
// lib/dashboard/notification_service.dart

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;

  /// Ajoute une notification dans la collection 'notifications'
  /// Usage: NotificationService.addNotification(title: "...", body: "...");
  static Future<void> addNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // debug log
      // print('Notification added: $title');
    } catch (e) {
      // print('NotificationService error: $e');
    }
  }
}
