import 'text_utils.dart';
import 'creative_design.dart';
import 'package:flutter/material.dart';
import 'package:app_gestion_docu/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUp_2 extends StatefulWidget {
  const SignUp_2({super.key});

  @override
  _SignUp_2State createState() => _SignUp_2State();
}

class _SignUp_2State extends State<SignUp_2> {
  final _auth = FirebaseAuth.instance;

  // Contrôleurs
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _cpassword = TextEditingController();

  // États de validation
  bool _nameValid = true;
  bool _emailValid = true;
  bool _passwordValid = true;
  bool _cpasswordValid = true;
  bool _isLoading = false;
  bool showHide = true;

  // Validations
  void _validateName(String val) => _nameValid = val.trim().length >= 3;
  void _validateEmail(String val) => _emailValid = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$",
  ).hasMatch(val.trim());
  void _validatePassword(String val) => _passwordValid = val.length >= 6;
  void _validateCPassword(String val) =>
      _cpasswordValid = val == _password.text;

  Future<void> _signUp() async {
    _validateName(_name.text);
    _validateEmail(_email.text);
    _validatePassword(_password.text);
    _validateCPassword(_cpassword.text);

    setState(() {}); // Refresh pour afficher erreurs

    if (!_nameValid || !_emailValid || !_passwordValid || !_cpasswordValid) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // 1️⃣ Création de l'utilisateur dans Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: _password.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        // 2️⃣ Sauvegarde des infos supplémentaires dans Firestore
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "name": _name.text.trim(),
          "email": _email.text.trim(),
          "role": "user", // tu peux mettre "admin" si besoin
          "createdAt": DateTime.now(),
        });
      }

      // 3️⃣ Message succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Compte créé avec succès")),
      );

      // 4️⃣ Redirection après succès
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login_2()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case "email-already-in-use":
          errorMessage = "⚠️ Cet email est déjà utilisé.";
          break;
        case "invalid-email":
          errorMessage = "❌ Format d'email invalide.";
          break;
        case "weak-password":
          errorMessage = "🔑 Mot de passe trop faible.";
          break;
        default:
          errorMessage = "Erreur : ${e.message}";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur inattendue : $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TextUtils.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: TextUtils.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 25),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Creative_Design()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height / 12),
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: TextUtils.white,
                  shadows: const [
                    BoxShadow(
                      color: Color.fromARGB(255, 255, 198, 10),
                      blurRadius: 13,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Full Name
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: const Icon(Icons.person),
                  errorText: _nameValid ? null : "Enter valid name",
                ),
                onChanged: (val) {
                  _validateName(val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              // Email
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  errorText: _emailValid ? null : "Enter valid email",
                ),
                onChanged: (val) {
                  _validateEmail(val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              // Password
              TextField(
                controller: _password,
                obscureText: showHide,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  errorText: _passwordValid ? null : "Password min 6 chars",
                  suffixIcon: IconButton(
                    icon: Icon(
                      showHide ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => showHide = !showHide),
                  ),
                ),
                onChanged: (val) {
                  _validatePassword(val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              // Confirm Password
              TextField(
                controller: _cpassword,
                obscureText: showHide,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: const Icon(Icons.lock),
                  errorText: _cpasswordValid ? null : "Passwords do not match",
                ),
                onChanged: (val) {
                  _validateCPassword(val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),
              // Sign Up Button
              InkWell(
                onTap: _isLoading ? null : _signUp,
                child: Container(
                  width: 150,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 255, 198, 10),
                        Color.fromARGB(255, 254, 252, 250),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: TextUtils.grey,
                        blurRadius: 13,
                        offset: Offset(2.5, 4.5),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SIGN UP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Login_2()),
                      );
                    },
                    child: const Text(
                      "Sign in",
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 198, 10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
