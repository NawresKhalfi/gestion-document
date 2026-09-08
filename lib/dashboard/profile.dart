import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _coverPhoto;
  String? _coverPhotoBase64;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Charger les données du profil depuis Firestore
  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();
        if (snapshot.exists) {
          final data = snapshot.data()!;
          setState(() {
            _nameController.text = data["name"] ?? "";
            _addressController.text = data["address"] ?? "";
            _contactController.text = data["contact"] ?? "";
            _emailController.text = data["email"] ?? user.email ?? "";
            _coverPhotoBase64 = data["coverPhotoBase64"];
          });
        }
      }
    } catch (e) {
      toast("Erreur lors du chargement: $e");
    }
  }

  /// Choisir une photo (caméra ou galerie)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _coverPhoto = File(pickedFile.path);
      });
      final bytes = await pickedFile.readAsBytes();
      _coverPhotoBase64 = base64Encode(bytes);
    }
  }

  /// Sauvegarder dans Firestore
  Future<void> _saveProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef = FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid);

        // Récupérer l’ancienne photo déjà stockée
        final snapshot = await docRef.get();
        String? oldPhotoBase64 = snapshot.exists
            ? (snapshot.data() as Map<String, dynamic>)["coverPhotoBase64"]
            : null;

        await docRef.set({
          "uid": user.uid,
          "name": _nameController.text.trim(),
          "address": _addressController.text.trim(),
          "contact": _contactController.text.trim(),
          "email": _emailController.text.trim(),
          "coverPhotoBase64": _coverPhotoBase64 ?? oldPhotoBase64 ?? "",
          "updatedAt": DateTime.now(),
        }, SetOptions(merge: true));

        toast("Profil sauvegardé avec succès !");
      }
    } catch (e) {
      toast("Erreur: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil"),
        backgroundColor: Color.fromARGB(255, 255, 198, 10),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Cover Photo
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                image: _coverPhoto != null
                    ? DecorationImage(
                        image: FileImage(_coverPhoto!),
                        fit: BoxFit.cover,
                      )
                    : (_coverPhotoBase64 != null &&
                          _coverPhotoBase64!.isNotEmpty)
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(_coverPhotoBase64!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text("Choisir depuis la galerie"),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text("Prendre une photo"),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Cover Photo"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Formulaire avec labels
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AppTextField(
                    controller: _nameController,
                    textFieldType: TextFieldType.NAME,
                    decoration: const InputDecoration(labelText: "Nom"),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _addressController,
                    textFieldType: TextFieldType.ADDRESS,
                    decoration: const InputDecoration(labelText: "Adresse"),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _contactController,
                    textFieldType: TextFieldType.PHONE,
                    decoration: const InputDecoration(labelText: "Contact"),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailController,
                    textFieldType: TextFieldType.EMAIL,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  const SizedBox(height: 30),
                  AppButton(
                    color: Color.fromARGB(255, 255, 198, 10),
                    textColor: Colors.white,
                    text: "Save",
                    width: context.width(),
                    onTap: _saveProfile,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
