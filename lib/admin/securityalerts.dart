import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final Color primaryColor = const Color.fromARGB(255, 255, 198, 10);
final Color backgroundColor = Colors.black;
final Color textColor = Colors.white;
final Color cardColor = const Color(0xFF121212);

/// Écran des alertes de sécurité.
/// Les données sont lues depuis la collection `access_logs`
/// en ne gardant que les entrées avec `accepted == false`.
class SecurityAlertsScreen extends StatelessWidget {
  const SecurityAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Alertes de sécurité'),
        backgroundColor: Colors.black,
        foregroundColor: primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('access_logs')
            .where('accepted', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement des alertes.',
                style: TextStyle(color: textColor),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'Aucune alerte de sécurité détectée.',
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
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
              final note = (data['note'] ?? '') as String;
              final timestamp = data['timestamp'];

              String dateLabel = '';
              if (timestamp is Timestamp) {
                final d = timestamp.toDate();
                dateLabel =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
                    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
              }

              return Card(
                color: cardColor,
                child: ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                  ),
                  title: Text(
                    '$gesture • ALERTE',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    [
                      if (dateLabel.isNotEmpty) dateLabel,
                      if (uid.isNotEmpty) 'UID: $uid',
                      if (note.isNotEmpty) note,
                    ].join(' • '),
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

