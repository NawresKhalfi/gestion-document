import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("À propos de nous"),
        backgroundColor: const Color.fromARGB(255, 255, 198, 10),
        leading: BackButton(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/dc.jpg',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          24.height,
          Text("Notre Application", style: boldTextStyle(size: 20)),
          8.height,
          Text(
            "Notre solution de gestion de documents vous permet de stocker, organiser, partager et sécuriser vos fichiers en toute simplicité. "
            "Elle intègre l’intelligence artificielle pour la reconnaissance faciale et la détection de gestes lors de l’envoi ou réception de documents.",
            style: secondaryTextStyle(),
          ),
          24.height,
          Text("TSE Consultant INT", style: boldTextStyle(size: 20)),
          8.height,
          Text(
            "TSE Consultant INT est une société innovante spécialisée en technologies numériques, "
            "solutions IoT et systèmes intelligents. Nous accompagnons nos clients dans la transformation digitale à travers des solutions modernes, performantes et sécurisées.",
            style: secondaryTextStyle(),
          ),
          24.height,
          Text("Contact", style: boldTextStyle(size: 20)),
          8.height,
          ListTile(
            leading: Icon(Icons.email, color: Colors.blue),
            title: Text("contact@tse-consulting.com"),
            subtitle: Text("Adresse e-mail"),
          ),
          ListTile(
            leading: Icon(Icons.location_on, color: Colors.red),
            title: Text("Tunis, Tunisie"),
            subtitle: Text("Siège social"),
          ),
        ],
      ),
    );
  }
}
