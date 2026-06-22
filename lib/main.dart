// lib/main.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';          // make sure this import is present
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Portal',
      theme: AppTheme.lightTheme,        // <-- no extra "Theme:"
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}