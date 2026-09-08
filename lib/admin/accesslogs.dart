import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final Color primaryColor = const Color.fromARGB(255, 255, 198, 10);
final Color backgroundColor = Colors.black;
final Color textColor = Colors.white;
final Color cardColor = const Color(0xFF121212);

class AccessLogsScreen extends StatelessWidget {
  const AccessLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Historique d'accès"),
        backgroundColor: Colors.black,
        foregroundColor: primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('access_logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur de chargement des logs",
                style: TextStyle(color: textColor),
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "Aucun historique trouvé.",
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
              final uid = (data['uid'] ?? '') as String;
              final gesture = (data['gesture'] ?? 'Action') as String;
              final accepted = (data['accepted'] ?? false) as bool;
              final note = (data['note'] ?? '') as String;
              final timestamp = data['timestamp'];

              String dateLabel = '';
              if (timestamp is Timestamp) {
                final date = timestamp.toDate();
                dateLabel =
                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
                    "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
              }

              final statusLabel = accepted ? "ACCEPTÉ" : "REFUSÉ";

              return Card(
                color: cardColor,
                child: ListTile(
                  leading: Icon(
                    accepted ? Icons.check_circle : Icons.block,
                    color: accepted ? Colors.greenAccent : Colors.redAccent,
                  ),
                  title: Text(
                    "$gesture • $statusLabel",
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    [
                      if (dateLabel.isNotEmpty) dateLabel,
                      if (uid.isNotEmpty) "UID: $uid",
                      if (note.isNotEmpty) note,
                    ].join(" • "),
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

