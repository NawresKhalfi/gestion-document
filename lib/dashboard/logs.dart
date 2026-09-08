import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_gestion_docu/dashboard/access_log_service.dart';

class AccessHistoryScreen extends StatelessWidget {
  const AccessHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historique d'accès"),
        backgroundColor: const Color.fromARGB(255, 255, 198, 10),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AccessLogService.getUserLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Aucun historique trouvé."));
          }

          final logs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final tsA = (a['timestamp'] as Timestamp?);
              final tsB = (b['timestamp'] as Timestamp?);
              final millisA = tsA?.millisecondsSinceEpoch ?? 0;
              final millisB = tsB?.millisecondsSinceEpoch ?? 0;
              return millisB.compareTo(millisA);
            });

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index].data() as Map<String, dynamic>;
              final date = log['timestamp'] != null
                  ? DateFormat(
                      'dd/MM/yyyy – HH:mm',
                    ).format((log['timestamp'] as Timestamp).toDate())
                  : "Date inconnue";

              final bool faceRecognized = log['faceRecognized'] ?? false;
              final String gesture = log['gesture'] ?? 'Inconnu';
              final bool accepted = log['accepted'] ?? false;
              final String? note = log['note'] as String?;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    accepted ? Icons.check_circle : Icons.cancel,
                    color: accepted ? Colors.green : Colors.red,
                    size: 30,
                  ),
                  title: Text(
                    faceRecognized ? "Visage reconnu" : "Visage non reconnu",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text("Geste : $gesture"),
                      if (note != null && note.isNotEmpty)
                        Text("Note : $note"),
                      Text("Date : $date"),
                    ],
                  ),
                  trailing: Text(
                    accepted ? "Accepté" : "Refusé",
                    style: TextStyle(
                      color: accepted ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
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
