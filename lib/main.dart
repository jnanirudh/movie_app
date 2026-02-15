import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this
import 'firebase_options.dart'; // This will exist after Step C
import 'package:movie_app/theme/dark_mode.dart';
import 'package:movie_app/theme/light_mode.dart';
import 'screens/login_screen.dart';

// Change main to async
void main() async {
  // Required handshake for Firebase
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Review App',
      home: const LoginScreen(),
      theme: lightMode,
      darkTheme: darkMode,
    );
  }
}