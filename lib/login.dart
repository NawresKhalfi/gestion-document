import 'home.dart';
import 'text_utils.dart';
import 'creative_design.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_gestion_docu/dashboard/dashboard.dart';
import 'package:app_gestion_docu/admin/dhashboardadmin.dart';
import 'package:app_gestion_docu/dashboard/notification.dart';
import 'package:app_gestion_docu/dashboard/notification_service.dart';

class Login_2 extends StatefulWidget {
  const Login_2({Key? key}) : super(key: key);

  @override
  _Login_2State createState() => _Login_2State();
}

class _Login_2State extends State<Login_2> {
  String checkEmail = "";
  String checkPassword = "";

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _emailValid = true;
  bool _passwordValid = true;
  bool showHide = true;

  final double size10 = 10;
  final double size20 = 20;
  final double size150 = 150;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _emailValidation(String val) {
    _emailValid = RegExp(
      r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
    ).hasMatch(val.trim());
  }

  void _passwordValidation(String val) {
    _passwordValid = val.trim().length >= 6;
  }

  Future<void> _login() async {
    _emailValidation(_emailController.text);
    _passwordValidation(_passwordController.text);

    setState(() {});

    if (!_emailValid || !_passwordValid) {
      // show an error quick feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez vérifier email et mot de passe."),
        ),
      );
      return;
    }

    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final User? user = userCredential.user;

      // Notification Firestore (success)
      await NotificationService.addNotification(
        title: "Connexion réussie",
        body:
            "L'utilisateur ${_emailController.text.trim()} s'est connecté avec succès.",
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("🔓 Connexion réussie")));

      if (user != null) {
        if (user.email == "admin@gmail.com") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => T6Dashboard()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Notification Firestore (failed)
      await NotificationService.addNotification(
        title: "Échec de connexion",
        body: "Erreur pour ${_emailController.text.trim()}: ${e.code}",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'authentification : ${e.message}")),
      );
    } catch (e) {
      // other errors
      await NotificationService.addNotification(
        title: "Échec de connexion",
        body: "Erreur pour ${_emailController.text.trim()}: $e",
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: TextUtils.white,
        elevation: 0.0,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Creative_Design()),
            );
          },
          icon: const Icon(Icons.arrow_back, size: 25),
        ),
      ),
      backgroundColor: TextUtils.white,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(flex: 1, child: SizedBox()),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: TextUtils.white,
                          fontSize: 40,
                          letterSpacing: 1,
                          shadows: const [
                            BoxShadow(
                              color: Color.fromARGB(255, 255, 198, 10),
                              blurRadius: 13,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Please sign in to continue",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: TextUtils.black54,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        onChanged: (value) {
                          _emailValidation(value);
                          checkEmail = value;
                          setState(() {});
                        },
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(
                            color: TextUtils.grey,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(Icons.email),
                          fillColor: TextUtils.white,
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: TextUtils.grey,
                              width: 1.5,
                            ),
                          ),
                          errorText: !_emailValid
                              ? "Enter valid email id"
                              : null,
                        ),
                        style: TextStyle(
                          color: !_emailValid
                              ? const Color.fromARGB(255, 255, 198, 10)
                              : TextUtils.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _passwordController,
                        obscureText: showHide,
                        onChanged: (value) {
                          _passwordValidation(value);
                          checkPassword = value;
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(
                            color: TextUtils.grey,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          errorText: !_passwordValid
                              ? "Password must be at least 6 characters"
                              : null,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                showHide = !showHide;
                              });
                            },
                            icon: Icon(
                              showHide
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color.fromARGB(255, 255, 198, 10),
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: !_passwordValid
                              ? const Color.fromARGB(255, 255, 198, 10)
                              : TextUtils.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _login,
                        child: Container(
                          alignment: Alignment.center,
                          width: size150,
                          height: 60,
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
                                offset: const Offset(2.5, 4.5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "LOG IN",
                                style: TextStyle(
                                  color: TextUtils.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: size20,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUp_2()),
                );
              },
              child: const Text(
                " Sign up",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color.fromARGB(255, 255, 198, 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
