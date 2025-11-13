// lib/common/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Colors
  static const Color primaryColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFFF8F9FD);
  static const Color sidebarColor = Colors.white;
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textLight = Color(0xFF888888);

  // Light Theme (The one we want)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Poppins',

      // We handle card styling in the widgets directly to avoid build errors
      cardColor: Colors.white,

      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textDark, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: textLight),
      ),

      iconTheme: const IconThemeData(color: textLight),
    );
  }

  // Dark Theme (Fallback to prevent errors if referenced)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF1a1a2e),
    );
  }
}