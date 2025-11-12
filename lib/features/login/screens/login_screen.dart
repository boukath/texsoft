// lib/features/login/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../../../common/widgets/gradient_background.dart';
import '../widgets/glass_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- FIX: Removed 'const' from Scaffold ---
    return Scaffold(
      body: Stack(
        children: [
          // This widget (the background) CAN be const, which is good.
          const GradientBackground(),

          // This part of the tree (the form) CANNOT be const.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              // --- FIX: Removed 'const' from GlassForm() ---
              child: GlassForm(),
            ),
          ),
        ],
      ),
    );
  }
}