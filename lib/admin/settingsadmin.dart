import 'package:flutter/material.dart';

final Color primaryColor = Color.fromARGB(255, 255, 198, 10);
final Color backgroundColor = Colors.black;
final Color textColor = Colors.white;
final Color cardColor = Color(0xFF121212);

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool facialRecognition = true;
  double gestureSensitivity = 0.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text("Paramètres"),
        backgroundColor: Colors.black,
        foregroundColor: primaryColor,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(
              "Reconnaissance faciale",
              style: TextStyle(color: textColor),
            ),
            value: facialRecognition,
            activeColor: primaryColor,
            onChanged: (val) {
              setState(() {
                facialRecognition = val;
              });
            },
          ),
          SizedBox(height: 24),
          Text(
            "Sensibilité détection gestes",
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            activeColor: primaryColor,
            inactiveColor: Colors.grey[700],
            value: gestureSensitivity,
            min: 0,
            max: 1,
            divisions: 10,
            label: (gestureSensitivity * 100).toInt().toString(),
            onChanged: (val) {
              setState(() {
                gestureSensitivity = val;
              });
            },
          ),
          SizedBox(height: 24),
          ListTile(
            title: Text(
              "Gestion des notifications",
              style: TextStyle(color: textColor),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: primaryColor),
            onTap: () {
              // Aller à la gestion notifications
            },
          ),
          ListTile(
            title: Text(
              "Gestion des caméras connectées",
              style: TextStyle(color: textColor),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: primaryColor),
            onTap: () {
              // Aller à la gestion caméras
            },
          ),
        ],
      ),
    );
  }
}
