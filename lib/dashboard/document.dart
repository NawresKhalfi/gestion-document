import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import 'package:app_gestion_docu/dashboard/notification.dart';
import 'package:app_gestion_docu/dashboard/notification_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_file/open_file.dart';

class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({Key? key}) : super(key: key);

  @override
  State<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // 🔹 Fonction utilitaire : ajouter une notification Firestore
  Future<void> _addNotification(String title, String message) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'message': message,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur notification : $e');
    }
  }

  // 🔹 Récupérer mes documents
  Stream<QuerySnapshot> getMyDocuments() {
    return FirebaseFirestore.instance
        .collection('documents')
        .where('ownerId', isEqualTo: user!.uid)
        .snapshots();
  }

  // 🔹 Récupérer mes documents reçus
  Stream<QuerySnapshot> getReceivedDocuments() {
    return FirebaseFirestore.instance
        .collection('received_documents')
        .where('receiverId', isEqualTo: user!.uid)
        .snapshots();
  }

  // 🟡 Génère des infos métier pour le résumé
  _DocumentSummaryData _buildSummaryData(
    Map<String, dynamic> data, {
    bool isReceived = false,
  }) {
    final fileName = (data['fileName'] ?? 'Document sans nom') as String;
    final lowerName = fileName.toLowerCase();

    final topics = <String>[];
    if (lowerName.contains('contrat')) topics.add('Contrat');
    if (lowerName.contains('facture')) topics.add('Finance');
    if (lowerName.contains('rapport')) topics.add('Rapport');
    if (lowerName.contains('note')) topics.add('Note interne');
    if (topics.isEmpty) topics.add('Documentation');

    final mimeType =
        (data['mimeType'] as String?) ?? lookupMimeType(fileName) ?? 'application/octet-stream';

    final int size =
        (data['sizeBytes'] is int) ? data['sizeBytes'] as int : 0;

    String recommendation = "Document prêt pour archivage.";
    if (mimeType.contains('pdf')) {
      recommendation = "Vérifie la conformité PDF/A avant diffusion.";
    } else if (mimeType.contains('image')) {
      recommendation = "Pense à lancer l'OCR pour la recherche plein texte.";
    } else if (mimeType.contains('word') ||
        mimeType.contains('application/msword') ||
        fileName.endsWith('.docx')) {
      recommendation = "Convertis en PDF signé avant envoi externe.";
    }

    final compliance = topics.contains('Finance')
        ? "Conservation 10 ans et accès limité au contrôle interne."
        : topics.contains('Contrat')
            ? "Signature électronique requise + suivi des avenants."
            : "Respecte la matrice de confidentialité Doc-Geste.";

    final timestamp = data['timestamp'];
    final formattedDate = _formatTimestamp(timestamp);

    final ownerLabel = isReceived
        ? (data['senderEmail'] ?? 'Expéditeur inconnu')
        : "Moi (UID ${user?.uid.substring(0, 6) ?? ''})";

    return _DocumentSummaryData(
      fileName: fileName,
      mimeType: mimeType,
      humanSize: _humanSize(size),
      topics: topics,
      recommendation: recommendation,
      compliance: compliance,
      ownerLabel: ownerLabel,
      createdAt: formattedDate,
    );
  }

  String _humanSize(int bytes) {
    if (bytes <= 0) return "Taille inconnue";
    const units = ['octets', 'Ko', 'Mo', 'Go'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size > 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return "${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[unitIndex]}";
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/${date.year}";
    }
    return "Date non renseignée";
  }

  void _openSummarySheet(
    Map<String, dynamic> data, {
    bool isReceived = false,
  }) {
    final summary = _buildSummaryData(data, isReceived: isReceived);
    final fileUrl = (data['fileUrl'] as String?) ?? '';
    final legacyBase64 = data['fileBase64'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DocumentSummarySheet(
        summary: summary,
        loadContentSummary: () =>
            _summarizeContentAsync(fileUrl, summary.mimeType, legacyBase64),
      ),
    );
  }

  Future<String> _summarizeContentAsync(
    String fileUrl,
    String mimeType,
    String? fallbackBase64,
  ) async {
    Uint8List? bytes;

    if (fileUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(fileUrl));
        if (response.statusCode == 200) {
          bytes = response.bodyBytes;
        }
      } catch (e) {
        debugPrint("Erreur téléchargement résumé: $e");
      }
    }

    if (bytes == null &&
        fallbackBase64 != null &&
        fallbackBase64.trim().isNotEmpty) {
      try {
        bytes = base64Decode(fallbackBase64);
      } catch (e) {
        debugPrint("Erreur décodage base64 legacy: $e");
      }
    }

    if (bytes == null || bytes.isEmpty) {
      return "Résumé indisponible : contenu non accessible.";
    }

    final normalizedMime = mimeType.toLowerCase();
    if (normalizedMime.contains('pdf')) {
      final pdfText = await _extractPdfTextFromBytes(bytes);
      if (pdfText.isNotEmpty) return _buildPlainTextSummary(pdfText);
    }

    final plainText = _extractPlainTextFromBytes(bytes);
    if (plainText.isNotEmpty) return _buildPlainTextSummary(plainText);

    return "Résumé indisponible pour ce format (binaire ou chiffré).";
  }

  Future<String> _extractPdfTextFromBytes(Uint8List bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final buffer = StringBuffer();
      final pageCount = document.pages.count;
      final pagesToRead = math.max(1, math.min(pageCount, 3));

      for (int i = 0; i < pagesToRead; i++) {
        final text = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        if (text.trim().isNotEmpty) buffer.writeln(text.trim());
        if (buffer.length > 3000) break;
      }

      if (buffer.isEmpty) buffer.writeln(extractor.extractText().trim());
      document.dispose();
      return buffer.toString();
    } catch (e) {
      debugPrint("Erreur extraction PDF: $e");
      return '';
    }
  }

  String _extractPlainTextFromBytes(Uint8List bytes) {
    try {
      final decoded = utf8.decode(bytes, allowMalformed: true);
      if (decoded.isEmpty) return '';

      final printable = decoded.codeUnits.where((codeUnit) {
        final isPrintableAscii = codeUnit >= 32 && codeUnit <= 126;
        final isExtendedLatin = codeUnit >= 160 && codeUnit <= 255;
        final isWhitespace = codeUnit == 10 || codeUnit == 13 || codeUnit == 9;
        return isPrintableAscii || isExtendedLatin || isWhitespace;
      }).length;

      if (decoded.isEmpty || printable / decoded.length < 0.65) {
        return '';
      }

      return decoded.replaceAll(RegExp(r'[^\x0A\x0D\x20-\x7EÀ-ÿ]'), ' ');
    } catch (e) {
      debugPrint("Erreur extraction texte: $e");
      return '';
    }
  }

  String _buildPlainTextSummary(String rawText) {
    final normalizedText = rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalizedText.isEmpty) {
      return "Contenu non lisible, impossible de générer un résumé.";
    }

    final sentences = normalizedText.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.isEmpty) {
      return normalizedText.length > 280
          ? "${normalizedText.substring(0, 280)}..."
          : normalizedText;
    }

    final buffer = <String>[];
    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.length < 5) continue;
      buffer.add(trimmed);
      if (buffer.length == 3) break;
    }

    if (buffer.isEmpty) {
      return normalizedText.length > 200
          ? "${normalizedText.substring(0, 200)}..."
          : normalizedText;
    }

    final summary = buffer.join(' ');
    return summary.length > 320 ? "${summary.substring(0, 320)}..." : summary;
  }

  // 🔹 Ajouter un fichier (Firebase Storage + Firestore sans base64)
  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      final fileName = file.name;
      final mimeType =
          lookupMimeType(fileName) ?? 'application/octet-stream';
      final sizeBytes = file.bytes!.length;

      // 1️⃣ Upload vers Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_files')
          .child(user!.uid)
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      await storageRef.putData(
        file.bytes!,
        SettableMetadata(contentType: mimeType),
      );

      final downloadUrl = await storageRef.getDownloadURL();

      // 2️⃣ Enregistrer les MÉTADONNÉES dans Firestore
      await FirebaseFirestore.instance.collection('documents').add({
        'ownerId': user!.uid,
        'fileName': fileName,
        'fileUrl': downloadUrl,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 🔔 Notification automatique
      await _addNotification(
        "Ajout de document",
        "Le document '$fileName' a été ajouté avec succès.",
      );

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Fichier "$fileName" ajouté')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  // 🔹 Renommer un document
  Future<void> renameDocument(String docId, String oldName) async {
    TextEditingController controller = TextEditingController(text: oldName);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Renommer le fichier"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('documents')
                  .doc(docId)
                  .update({'fileName': controller.text});
              Navigator.pop(context);

              // 🔔 Notification renommage
              await _addNotification(
                "Renommage de fichier",
                "Le fichier '$oldName' a été renommé en '${controller.text}'.",
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // 🔹 Supprimer un document
  Future<void> deleteDocument(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('documents')
          .doc(docId)
          .get();

      String fileName = doc['fileName'] ?? '';
      String? fileUrl = doc.data()?['fileUrl'] as String?;

      // Optionnel : supprimer aussi du Storage si on peut retrouver la ref
      if (fileUrl != null && fileUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(fileUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Erreur suppression Storage : $e');
        }
      }

      await FirebaseFirestore.instance
          .collection('documents')
          .doc(docId)
          .delete();

      // 🔔 Notification suppression
      await _addNotification(
        "Suppression de document",
        "Le document '$fileName' a été supprimé.",
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("🗑️ '$fileName' supprimé")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  // 🔹 Partager par email (via URL Storage, sans base64)
  Future<void> shareDocument(
    String fileName,
    String fileUrl,
    String receiverEmail,
    String mimeType,
  ) async {
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: receiverEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Aucun utilisateur trouvé pour cet email')),
        );
        return;
      }

      final receiverId = userQuery.docs.first.id;

      await FirebaseFirestore.instance.collection('received_documents').add({
        'receiverId': receiverId,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'senderEmail': user!.email,
        'mimeType': mimeType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 🔔 Notification partage
      await _addNotification(
        "Partage de document",
        "Le fichier '$fileName' a été partagé avec $receiverEmail.",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Fichier partagé avec $receiverEmail')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de partage : $e')));
    }
  }

  // 🔹 Ouvrir un fichier stocké dans Firebase Storage (via URL)
  Future<void> openRemoteFile(String fileName, String fileUrl) async {
    try {
      if (kIsWeb) {
        final uri = Uri.parse(fileUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception("Impossible d'ouvrir l'URL");
        }
      } else {
        final response = await http.get(Uri.parse(fileUrl));
        if (response.statusCode != 200) {
          throw Exception("Erreur de téléchargement (${response.statusCode})");
        }

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        await OpenFile.open(file.path);
      }

      // 🔔 Notification ouverture
      await _addNotification(
        "Ouverture de fichier",
        "Le fichier '$fileName' a été ouvert.",
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur ouverture : $e')));
    }
  }

  // 🔹 Télécharger un fichier reçu (via URL)
  Future<void> downloadReceivedFile(String fileName, String fileUrl) async {
    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode != 200) {
        throw Exception("Erreur de téléchargement (${response.statusCode})");
      }

      if (kIsWeb) {
        final uri = Uri.parse(fileUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Fichier enregistré : ${file.path}')),
        );
      }

      // 🔔 Notification téléchargement
      await _addNotification(
        "Téléchargement de fichier",
        "Le fichier '$fileName' a été téléchargé.",
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur téléchargement : $e')));
    }
  }

  // 🔹 Widget : Mes documents
  Widget buildMyDocuments() {
    return StreamBuilder<QuerySnapshot>(
      stream: getMyDocuments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final fileName = data['fileName'] as String? ?? '';
            final createdLabel = _formatTimestamp(data['timestamp']);
            final fileUrl = data['fileUrl'] as String? ?? '';
            final mimeType =
                (data['mimeType'] as String?) ?? lookupMimeType(fileName) ?? 'application/octet-stream';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insert_drive_file, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Ajouté le $createdLabel",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new,
                              color: Colors.blueGrey),
                          onPressed: fileUrl.isEmpty
                              ? null
                              : () => openRemoteFile(fileName, fileUrl),
                          tooltip: "Ouvrir",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => renameDocument(doc.id, fileName),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteDocument(doc.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.green),
                          onPressed: () async {
                            final emailController = TextEditingController();
                            await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Partager via email'),
                                content: TextField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    hintText: 'Email destinataire',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await shareDocument(
                                        fileName,
                                        fileUrl,
                                        emailController.text.trim(),
                                        mimeType,
                                      );
                                    },
                                    child: const Text('Envoyer'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.article, color: Colors.black87),
                          onPressed: () => _openSummarySheet(data),
                          tooltip: "Résumé intelligent",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Widget : Documents reçus
  Widget buildReceivedDocuments() {
    return StreamBuilder<QuerySnapshot>(
      stream: getReceivedDocuments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final fileName = data['fileName'] as String? ?? '';
            final sender = data['senderEmail'] as String? ?? '';
            final receivedLabel = _formatTimestamp(data['timestamp']);
            final fileUrl = data['fileUrl'] as String? ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mail,
                            color: Color.fromARGB(255, 255, 198, 10)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "De : $sender",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              if (receivedLabel != "Date non renseignée")
                                Text(
                                  "Reçu le $receivedLabel",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.open_in_new, color: Colors.blue),
                          onPressed: fileUrl.isEmpty
                              ? null
                              : () => openRemoteFile(fileName, fileUrl),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.download, color: Colors.orange),
                          onPressed: fileUrl.isEmpty
                              ? null
                              : () => downloadReceivedFile(
                                    fileName,
                                    fileUrl,
                                  ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.article, color: Colors.black87),
                          onPressed: () =>
                              _openSummarySheet(data, isReceived: true),
                          tooltip: "Résumé intelligent",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Interface principale
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Management"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "My Documents"),
            Tab(text: "Received Documents"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [buildMyDocuments(), buildReceivedDocuments()],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 255, 198, 10),
        onPressed: pickFile,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DocumentSummaryData {
  final String fileName;
  final String mimeType;
  final String humanSize;
  final List<String> topics;
  final String recommendation;
  final String compliance;
  final String ownerLabel;
  final String createdAt;

  _DocumentSummaryData({
    required this.fileName,
    required this.mimeType,
    required this.humanSize,
    required this.topics,
    required this.recommendation,
    required this.compliance,
    required this.ownerLabel,
    required this.createdAt,
  });
}

class _DocumentSummarySheet extends StatefulWidget {
  final _DocumentSummaryData summary;
  final Future<String> Function() loadContentSummary;

  const _DocumentSummarySheet({
    required this.summary,
    required this.loadContentSummary,
  });

  @override
  State<_DocumentSummarySheet> createState() => _DocumentSummarySheetState();
}

class _DocumentSummarySheetState extends State<_DocumentSummarySheet> {
  String? _contentSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.loadContentSummary().then((value) {
      if (!mounted) return;
      setState(() {
        _contentSummary = value;
        _isLoading = false;
      });
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _contentSummary = "Erreur lors de l'analyse du contenu : $error";
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.summary.fileName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${widget.summary.mimeType} • ${widget.summary.humanSize}",
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Créé le ${widget.summary.createdAt}",
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Propriétaire : ${widget.summary.ownerLabel}",
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.summary.topics
                  .map(
                    (topic) => Chip(
                      label: Text(topic),
                      backgroundColor:
                          const Color.fromARGB(255, 255, 239, 176),
                      labelStyle: const TextStyle(color: Colors.black87),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              "Résumé du contenu",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isLoading
                  ? "Analyse du contenu en cours..."
                  : (_contentSummary ??
                      "Résumé indisponible pour ce format."),
              style: const TextStyle(
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Recommandation métier",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.summary.recommendation,
              style: const TextStyle(
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Rappel conformité",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.summary.compliance,
              style: const TextStyle(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
