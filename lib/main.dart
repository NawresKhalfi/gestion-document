import 'package:flutter/material.dart';
import 'package:app_gestion_docu/home.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAZ-O1-wBfOq_Jl0bPueU1IgDqgukwZehY",
      authDomain: "appgestion-69fd2.firebaseapp.com",
      projectId: "appgestion-69fd2",
      storageBucket: "appgestion-69fd2.firebasestorage.app",
      messagingSenderId: "706350445499",
      appId: "1:706350445499 :web :f1376a729d77a0798e8a9e",
    ),
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: SignUp_2());
  }
}
