
// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:home_ease/screens/auth_wrapper.dart';
import 'package:home_ease/screens/home_screen.dart';
import 'package:home_ease/screens/login.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    
  );
     updateLastActive(); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomEase',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
       routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(userId: ''),
        // Add any other routes your app needs
      },
      // Optionally, set initial route
      initialRoute: '/',
    );
  }
}

Future<void> updateLastActive() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'lastActiveDate': FieldValue.serverTimestamp(),
    });
  }
}