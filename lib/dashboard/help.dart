import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Aide et Support"),
        backgroundColor: const Color.fromARGB(255, 255, 198, 10),
        leading: BackButton(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Questions fréquentes", style: boldTextStyle(size: 20)),
          16.height,
          ExpansionTile(
            title: Text(
              "Comment envoyer un document ?",
              style: primaryTextStyle(),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Allez dans l’onglet Documents > Cliquez sur le bouton + > Suivez les étapes.",
                  style: secondaryTextStyle(),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(
              "Comment confirmer un envoi par geste ou visage ?",
              style: primaryTextStyle(),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Lors de l’envoi, la caméra s’active automatiquement pour détecter votre visage ou geste de confirmation.",
                  style: secondaryTextStyle(),
                ),
              ),
            ],
          ),
          24.height,
          Text("Contactez-nous", style: boldTextStyle(size: 20)),
          16.height,
          ListTile(
            leading: Icon(Icons.email, color: Colors.blue),
            title: Text("support@app.com"),
            subtitle: Text("Envoyez-nous un email"),
          ),
          ListTile(
            leading: Icon(Icons.phone, color: Colors.green),
            title: Text("+216 99 123 456"),
            subtitle: Text("Appelez notre support technique"),
          ),
          ListTile(
            leading: Icon(Icons.help_outline, color: Colors.orange),
            title: Text("Centre d’aide"),
            subtitle: Text("Accédez à notre site FAQ"),
            onTap: () {
              // Lien vers un site externe
            },
          ),
        ],
      ),
    );
  }
}
