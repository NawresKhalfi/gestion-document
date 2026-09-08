import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_gestion_docu/admin/accesslogs.dart';
import 'package:app_gestion_docu/admin/settingsadmin.dart';
import 'package:app_gestion_docu/admin/securityalerts.dart';
import 'package:app_gestion_docu/admin/gestiondocument.dart';
import 'package:app_gestion_docu/admin/gestionutilisateur.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': Icons.people,
        'label': 'Gestion Utilisateurs',
        'screen': UserManagementScreen(),
      },
      {
        'icon': Icons.folder,
        'label': 'Gestion Documents',
        'screen': DocumentManagementScreen(),
      },
      {
        'icon': Icons.history,
        'label': 'Historique & Logs',
        'screen': AccessLogsScreen(),
      },
      {
        'icon': Icons.shield,
        'label': 'Alertes Sécurité',
        'screen': SecurityAlertsScreen(),
      },
      {
        'icon': Icons.settings,
        'label': 'Paramètres',
        'screen': SettingsScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nombre d'utilisateurs (collection "users")
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final value = snapshot.hasData
                          ? snapshot.data!.docs.length.toString()
                          : '...';
                      return _statCard(
                        icon: Icons.people,
                        label: 'Utilisateurs',
                        value: value,
                      );
                    },
                  ),
                  // Nombre de documents (collection "documents")
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('documents')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final value = snapshot.hasData
                          ? snapshot.data!.docs.length.toString()
                          : '...';
                      return _statCard(
                        icon: Icons.folder,
                        label: 'Documents',
                        value: value,
                      );
                    },
                  ),
                  // Nombre d'alertes (logs avec accepted == false)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('access_logs')
                        .where('accepted', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final value = snapshot.hasData
                          ? snapshot.data!.docs.length.toString()
                          : '...';
                      return _statCard(
                        icon: Icons.warning,
                        label: 'Alertes',
                        value: value,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Action Buttons
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: actions.map((a) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => a['screen']),
                      );
                    },
                    child: _actionCard(icon: a['icon'], label: a['label']),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.amber, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _actionCard({required IconData icon, required String label}) {
    return Container(
      width: 150,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.amber, size: 34),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
