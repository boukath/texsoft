// lib/common/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor so no one can instantiate this class
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blueAccent,
      fontFamily: 'Roboto', // A clean, professional font
      scaffoldBackgroundColor: const Color(0xFF1a1a2e), // Dark background

      // Define the text field theme globally
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIconColor: Colors.white.withOpacity(0.7),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),

      // Define the elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent, // Accent color
          foregroundColor: Colors.white, // Text color
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}