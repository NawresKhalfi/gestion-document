import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final Color primaryColor = const Color.fromARGB(255, 255, 198, 10);
final Color backgroundColor = Colors.black;
final Color textColor = Colors.white;
final Color cardColor = const Color(0xFF121212);

class DocumentManagementScreen extends StatelessWidget {
  const DocumentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Gestion Documents"),
        backgroundColor: Colors.black,
        foregroundColor: primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('documents')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur de chargement des documents",
                style: TextStyle(color: textColor),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "Aucun document trouvé.",
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
              final title =
                  (data['fileName'] ?? 'Document sans nom') as String;
              final ownerId = data['ownerId'] as String? ?? '';
              final timestamp = data['timestamp'];

              String subtitle = "Propriétaire : $ownerId";
              if (timestamp is Timestamp) {
                final date = timestamp.toDate();
                subtitle +=
                    " • Ajouté le ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
              }

              return Card(
                color: cardColor,
                child: ListTile(
                  leading:
                      Icon(Icons.insert_drive_file, color: primaryColor),
                  title: Text(title, style: TextStyle(color: textColor)),
                  subtitle: Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      // Supprime le document de la collection "documents"
                      await FirebaseFirestore.instance
                          .collection('documents')
                          .doc(docs[index].id)
                          .delete();
                    },
                  ),
                  onTap: () {
                    // Plus tard : afficher les détails ou le résumé
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

