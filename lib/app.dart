// lib/app.dart
import 'package:flutter/material.dart';
import 'common/theme/app_theme.dart';
import 'features/login/screens/login_screen.dart';

class PosApp extends StatelessWidget {
  const PosApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Pro',
      debugShowCheckedModeBanner: false, // Hides the "debug" banner
      theme: AppTheme.darkTheme, // Using our centralized theme
      home: const LoginScreen(), // The new starting screen
    );
  }
}