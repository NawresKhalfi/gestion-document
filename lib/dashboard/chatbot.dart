import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Liste modifiable des messages
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          "Salut ! Je suis Docy, l'assistant collaboratif de Doc‑Geste. Pose une question sur la connexion, les documents, la détection intelligente ou les notifications, et je t'explique comment ça marche.",
      isUser: false,
    ),
  ];

  // Base de connaissances simple par mots‑clés
  final List<_BotRule> _knowledgeBase = const [
    _BotRule(
      keywords: ['classer', 'organiser', 'tri', 'dossier'],
      answer:
          "Pour classer un document, utilise une nomenclature claire (ex : 2025_04_contrat_clientX.pdf) et renseigne les métadonnées (propriétaire, confidentialité, durée d'archivage) dans l'écran Document Management.",
    ),
    _BotRule(
      keywords: ['format', 'pdf', 'scan', 'image'],
      answer:
          "On privilégie le PDF/A pour la conservation long terme. Les scans doivent être à 300 dpi avec OCR activé pour être bien retrouvés dans la recherche.",
    ),
    _BotRule(
      keywords: ['rgpd', 'sécur', 'confident', 'protection'],
      answer:
          "Les documents contenant des données personnelles doivent être stockés dans l'espace chiffré et partagés uniquement avec les équipes habilitées, selon la matrice de confidentialité définie dans l'application.",
    ),
    _BotRule(
      keywords: ['workflow', 'signature', 'validation'],
      answer:
          "Pour lancer un workflow de validation, ouvre le document puis utilise le bouton de partage/validation. Choisis les personnes à valider ; la signature électronique se déclenche à la dernière étape.",
    ),
    _BotRule(
      keywords: ['stockage', 'drive', 'cloud', 'sauvegarde'],
      answer:
          "Les documents actifs restent dans l'onglet My Documents. Les versions finales peuvent être archivées automatiquement dans le coffre‑fort selon les règles configurées dans l'application.",
    ),
    _BotRule(
      keywords: ['connexion', 'login', 'mot de passe', 'authentification'],
      answer:
          "Utilise ton email et ton mot de passe Doc‑Geste. En cas d'erreur, vérifie la connexion Internet et que tes identifiants correspondent à ceux enregistrés dans Firebase Auth.",
    ),
    _BotRule(
      keywords: ['document', 'résumé', 'summary'],
      answer:
          "Dans l'écran Document Management, le bouton « Résumé intelligent » ouvre une fiche qui affiche les métadonnées et un résumé automatique du contenu pour les PDF ou textes lisibles.",
    ),
    _BotRule(
      keywords: ['visage', 'facial', 'détection', 'camera', 'identify'],
      answer:
          "La détection intelligente utilise la caméra avec ML Kit. Quand ton visage est reconnu puis validé (code PIN), tu peux enchaîner avec la détection de geste pour accéder à l'envoi de documents.",
    ),
    _BotRule(
      keywords: ['geste', 'main levée', 'pose', 'gesture'],
      answer:
          "Après validation du visage, l'application analyse la posture pour détecter une main levée au‑dessus de l'épaule. Si la main n'est pas détectée, refais le geste bien visible devant la caméra.",
    ),
    _BotRule(
      keywords: ['logs', 'historique', 'journal', 'accès'],
      answer:
          "L'onglet Logs affiche l'historique d'accès enregistré par AccessLogService : visage reconnu ou non, geste accepté/refusé, notes de sécurité, avec date et UID.",
    ),
    _BotRule(
      keywords: ['notification', 'alerte', 'notif'],
      answer:
          "Les notifications informent des événements importants (ajout/suppression de document, détection de visage/geste, erreurs). Elles sont aussi visibles dans l'historique et les alertes sécurité en mode admin.",
    ),
  ];

  final List<String> _suggestions = const [
    'Comment classer un contrat ?',
    'Comment fonctionne la détection de visage ?',
    'Où voir les logs d’accès ?',
    'Que fait le résumé intelligent ?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend([String? preset]) {
    final raw = preset ?? _controller.text;
    final text = raw.trim();
    if (text.isEmpty) return;

    // Ajout du message utilisateur
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _controller.clear();
    FocusScope.of(context).unfocus();
    _scrollToBottom();

    // Réponse du bot (logique simple par mots‑clés)
    final botReply = _buildResponse(text);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: botReply, isUser: false));
      });
      _scrollToBottom();
    });
  }

  String _buildResponse(String question) {
    final q = question.toLowerCase();

    for (final rule in _knowledgeBase) {
      final matches = rule.keywords
          .where((k) => q.contains(k.toLowerCase()))
          .length;
      if (matches >= 1) {
        return rule.answer;
      }
    }

    return "Je n'ai pas encore une réponse exacte pour ça. "
        "Précise‑moi l'écran (login, documents, détection intelligente, logs, admin) "
        "et ce que tu veux faire, et je t'indiquerai la procédure dans l'application.";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 198, 10),
        title: const Text('Assistant collaboratif'),
      ),
      body: Column(
        children: [
          // Bandeau d’explication
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 255, 198, 10),
                  Color.fromARGB(255, 255, 239, 176),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Espace collaboratif',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Discute avec Docy pour partager des bonnes pratiques et poser des questions sur la gestion documentaire intelligente.",
                  style: TextStyle(
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          // Liste des messages
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (_, index) {
                final message = _messages[index];
                final alignment = message.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft;
                final bubbleColor = message.isUser
                    ? const Color.fromARGB(255, 255, 198, 10)
                    : Colors.white;
                final textColor =
                    message.isUser ? Colors.black : Colors.black87;

                return Align(
                  alignment: alignment,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                        bottomRight: Radius.circular(message.isUser ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: _messages.length,
            ),
          ),
          // Barre de saisie + suggestions
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _suggestions.map((s) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(right: 8.0, bottom: 10),
                          child: ActionChip(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            backgroundColor: const Color.fromARGB(
                                255, 255, 239, 176),
                            label: Text(
                              s,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            onPressed: () => _handleSend(s),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSend(),
                          decoration: InputDecoration(
                            hintText:
                                'Décris ta question ou partage une astuce...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            const Color.fromARGB(255, 255, 198, 10),
                        child: IconButton(
                          icon:
                              const Icon(Icons.send, color: Colors.black),
                          onPressed: _handleSend,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _BotRule {
  final List<String> keywords;
  final String answer;

  const _BotRule({required this.keywords, required this.answer});
}

