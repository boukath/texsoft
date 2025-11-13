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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // <--- UPDATED: Changed to lightTheme
      home: const LoginScreen(),
    );
  }
}