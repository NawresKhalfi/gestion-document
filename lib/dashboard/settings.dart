import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Setting_2 extends StatefulWidget {
  @override
  _Setting_2State createState() => _Setting_2State();
}

class _Setting_2State extends State<Setting_2> {
  String _name = "Loading...";
  String _email = "Loading...";
  String? _coverPhotoBase64;
  String _phone = "Not set";
  String _dob = "Not set";
  String _language = "English";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _name = data["name"] ?? "Unknown";
          _email = data["email"] ?? user.email!;
          _coverPhotoBase64 = data["coverPhotoBase64"];
          _phone = data["phone"] ?? "Not set";
          _dob = data["dob"] ?? "Not set";
          _language = data["language"] ?? "English";
        });
      }
    }
  }

  Future<void> _updateUserField(String field, String value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {field: value},
      );

      // ✅ Correction ici : remplacer updateEmail() par verifyBeforeUpdateEmail()
      if (field == "email") {
        await user.verifyBeforeUpdateEmail(value);
      } else if (field == "password") {
        await user.updatePassword(value);
      }

      _loadUserData();
    }
  }

  void _openEditDialog(
    String title,
    String field,
    String initialValue, {
    bool isPassword = false,
  }) {
    TextEditingController controller = TextEditingController(
      text: initialValue,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change $title"),
        content: TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: "Enter new $title",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text("Save"),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _updateUserField(field, controller.text.trim());
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Function onTap,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.amber[700]),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => onTap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings"), centerTitle: true),
      body: ListView(
        children: [
          SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage:
                  _coverPhotoBase64 != null && _coverPhotoBase64!.isNotEmpty
                  ? MemoryImage(base64Decode(_coverPhotoBase64!))
                  : AssetImage("assets/images/default_avatar.png")
                        as ImageProvider,
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: Text(
              _name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(_email, style: TextStyle(color: Colors.grey)),
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.person,
            title: "Change Name",
            subtitle: "Current: $_name",
            onTap: () => _openEditDialog("Name", "name", _name),
          ),
          buildSettingItem(
            icon: Icons.lock,
            title: "Change Password",
            subtitle: "********",
            onTap: () =>
                _openEditDialog("Password", "password", "", isPassword: true),
          ),
          buildSettingItem(
            icon: Icons.email,
            title: "Change Email",
            subtitle: "Current: $_email",
            onTap: () => _openEditDialog("Email", "email", _email),
          ),
          buildSettingItem(
            icon: Icons.phone,
            title: "Change Mobile Number",
            subtitle: "Current: $_phone",
            onTap: () => _openEditDialog("Mobile Number", "phone", _phone),
          ),
          buildSettingItem(
            icon: Icons.calendar_today,
            title: "Change Date Of Birth",
            subtitle: "Current: $_dob",
            onTap: () => _openEditDialog("Date of Birth", "dob", _dob),
          ),
          buildSettingItem(
            icon: Icons.language,
            title: "Change Language",
            subtitle: "Current: $_language",
            onTap: () => _openEditDialog("Language", "language", _language),
          ),
        ],
      ),
    );
  }
}
