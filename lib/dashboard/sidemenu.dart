import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_gestion_docu/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_gestion_docu/dashboard/help.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_gestion_docu/dashboard/chatbot.dart';
import 'package:app_gestion_docu/dashboard/aboutus.dart';
import 'package:app_gestion_docu/dashboard/profile.dart';
import 'package:app_gestion_docu/dashboard/settings.dart';

class T1SideMenu extends StatefulWidget {
  @override
  _T1SideMenuState createState() => _T1SideMenuState();
}

class _T1SideMenuState extends State<T1SideMenu> {
  String _name = "John Doe";
  String _email = "john.doe@example.com";
  String? _coverPhotoBase64;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;

          setState(() {
            _name = data["name"] ?? "John Doe";
            _email = data["email"] ?? "john.doe@example.com";
            _coverPhotoBase64 = data["coverPhotoBase64"];
          });
        }
      }
    } catch (e) {
      print("Erreur lors du chargement des données utilisateur: $e");
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 30),
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    _coverPhotoBase64 != null && _coverPhotoBase64!.isNotEmpty
                    ? MemoryImage(base64Decode(_coverPhotoBase64!))
                    : AssetImage("assets/images/default_avatar.png")
                          as ImageProvider,
                backgroundColor: Color.fromARGB(255, 255, 198, 10),
              ),
              SizedBox(height: 10),
              Text(_name, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_email, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 30),

          buildMenuItem(context, Icons.person, "Profile", ProfileScreen()),
          buildMenuItem(context, Icons.help_outline, "Help", HelpScreen()),
          buildMenuItem(
            context,
            Icons.info_outline,
            "About Us",
            AboutUsScreen(),
          ),
          buildMenuItem(
            context,
            Icons.smart_toy_outlined,
            "Chatbot collaboratif",
            const ChatbotScreen(),
          ),
          buildMenuItem(context, Icons.settings, "Settings", Setting_2()),

          Divider(height: 32),

          buildMenuItem(context, Icons.logout, "Logout", Login_2()),
        ],
      ),
    );
  }

  Widget buildMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    Widget destination,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(label),
      trailing: Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => destination));
      },
    );
  }
}
