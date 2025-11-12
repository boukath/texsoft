// lib/features/login/widgets/login_button.dart
import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Logic to be added
        },
        // The style is now centrally managed by the theme in app_theme.dart
        child: const Text('Se connecter'),
      ),
    );
  }
}