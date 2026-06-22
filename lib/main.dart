import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';          // <-- add this import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Portal',
      theme: Theme: AppTheme.lightTheme,        // <-- use our custom theme
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
