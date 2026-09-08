import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final Color primaryColor = const Color.fromARGB(255, 255, 198, 10);
final Color backgroundColor = Colors.black;
final Color textColor = Colors.white;
final Color cardColor = const Color(0xFF121212);

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Gestion Utilisateurs"),
        backgroundColor: Colors.black,
        foregroundColor: primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur de chargement des utilisateurs",
                style: TextStyle(color: textColor),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "Aucun utilisateur trouvé.",
                style: TextStyle(color: Colors.grey[400]),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(color: Colors.grey[700]),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = (data["name"] ?? "Utilisateur sans nom") as String;
              final email = (data["email"] ?? "Email inconnu") as String;
              final role = (data["role"] ?? "user") as String;

              return Card(
                color: cardColor,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: TextStyle(color: backgroundColor),
                    ),
                  ),
                  title: Text(name, style: TextStyle(color: textColor)),
                  subtitle: Text(
                    email,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(color: backgroundColor),
                    ),
                  ),
                  onTap: () {
                    // Plus tard : écran détail / changement de rôle
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

