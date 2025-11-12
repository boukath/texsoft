// lib/main.dart
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // --- FIX: Removed the 'packagepackage:' typo
import 'dart:io'; // --- FIX: Added this import for 'Platform'
import 'app.dart';

Future<void> main() async {

  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for sqflite on Windows/Linux
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const PosApp());
}