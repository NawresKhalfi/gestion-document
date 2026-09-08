import 'chat.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contacts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>? ?? {};
              final String userId = user.id;
              final String userName =
                  (data['name'] as String?)?.trim().isNotEmpty == true
                      ? data['name'] as String
                      : "Utilisateur";
              final String coverPhotoBase64 =
                  (data['coverPhotoBase64'] as String?) ?? "";

              ImageProvider getUserImage() {
                if (coverPhotoBase64.isNotEmpty) {
                  try {
                    return MemoryImage(base64Decode(coverPhotoBase64));
                  } catch (e) {
                    return const AssetImage("assets/default_avatar.png");
                  }
                }
                return const AssetImage("assets/default_avatar.png");
              }

              return ListTile(
                leading: CircleAvatar(backgroundImage: getUserImage()),
                title: Text(userName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        receiverId: userId,
                        receiverName: userName,
                        receiverPhotoUrl: coverPhotoBase64,
                        receiverEmail: '',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
