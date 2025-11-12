// lib/common/widgets/gradient_background.dart
import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)], // Midnight blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}