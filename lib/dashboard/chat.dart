import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_gestion_docu/dashboard/notification_service.dart'; // 🔹 Import ajouté

class ChatPage extends StatefulWidget {
  final String receiverId; // UID de l'autre utilisateur
  const ChatPage({
    Key? key,
    required this.receiverId,
    required String receiverPhotoUrl,
    required String receiverEmail,
    required String receiverName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String receiverName = '';
  String receiverEmail = '';
  String receiverPhotoBase64 = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadReceiverInfo();
    _listenForIncomingMessages(); // 🔹 Écoute en continu pour les messages reçus
  }

  /// 🔹 Charger les infos de l’utilisateur (nom, photo base64, email)
  Future<void> _loadReceiverInfo() async {
    try {
      final receiverDoc = await _firestore
          .collection('users')
          .doc(widget.receiverId)
          .get();
      if (receiverDoc.exists) {
        setState(() {
          receiverName = receiverDoc['name'] ?? 'Utilisateur';
          receiverEmail = receiverDoc['email'] ?? '';
          receiverPhotoBase64 = receiverDoc['coverPhotoBase64'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du profil: $e');
    }
  }

  /// 🔹 Identifiant unique du chat
  String _getChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  /// 🔹 Envoi d’un message + notification
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = _auth.currentUser!;
    final message = _messageController.text.trim();
    _messageController.clear();

    final chatId = _getChatId(currentUser.uid, widget.receiverId);

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': currentUser.uid,
            'receiverId': widget.receiverId,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

      // 🔹 Ajouter une notification Firestore
      await NotificationService.addNotification(
        title: "Nouveau message envoyé",
        body: "Vous avez envoyé un message à $receiverName.",
      );
    } catch (e) {
      debugPrint("Erreur lors de l'envoi du message : $e");
    }
  }

  /// 🔹 Écouter les nouveaux messages entrants (non lus)
  void _listenForIncomingMessages() {
    if (_isListening) return; // évite plusieurs abonnements
    _isListening = true;

    final currentUser = _auth.currentUser!;
    final chatId = _getChatId(currentUser.uid, widget.receiverId);

    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
          for (var msg in snapshot.docs) {
            // 🔹 Notification Firestore pour message reçu
            await NotificationService.addNotification(
              title: "Nouveau message reçu",
              body: "Message de $receiverName : ${msg['message']}",
            );
          }
        });
  }

  /// 🔹 Marquer les messages reçus comme lus
  Future<void> _markMessagesAsRead() async {
    final currentUser = _auth.currentUser!;
    final chatId = _getChatId(currentUser.uid, widget.receiverId);

    final unread = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unread.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser!;
    final chatId = _getChatId(currentUser.uid, widget.receiverId);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC60A),
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: receiverPhotoBase64.isNotEmpty
                  ? MemoryImage(base64Decode(receiverPhotoBase64))
                  : const AssetImage('assets/default_user.png')
                        as ImageProvider,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiverName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (receiverEmail.isNotEmpty)
                  Text(
                    receiverEmail,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      /// 🟡 Corps principal : liste des messages + zone de saisie
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markMessagesAsRead();
                });

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser.uid;
                    final time = (msg['timestamp'] != null)
                        ? DateFormat(
                            'HH:mm',
                          ).format((msg['timestamp'] as Timestamp).toDate())
                        : '';

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFFFE082) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe
                                ? const Radius.circular(12)
                                : Radius.zero,
                            bottomRight: isMe
                                ? Radius.zero
                                : const Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 3,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              msg['message'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (time.isNotEmpty)
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                const SizedBox(width: 5),
                                if (isMe)
                                  Icon(
                                    msg['isRead'] == true
                                        ? Icons.done_all
                                        : Icons.check,
                                    size: 16,
                                    color: msg['isRead'] == true
                                        ? Colors.blue
                                        : Colors.black45,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// 🟢 Zone d’écriture du message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Écrire un message...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFFFC60A),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
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
