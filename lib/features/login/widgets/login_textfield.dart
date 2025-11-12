// lib/features/login/widgets/login_textfield.dart
import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller; // <--- ADD THIS

  const LoginTextField({
    Key? key,
    required this.label,
    required this.icon,
    required this.controller, // <--- ADD THIS
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, // <--- ADD THIS
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (value) { // Optional: Add validation
        if (value == null || value.isEmpty) {
          return 'Ce champ ne peut pas être vide'; // French error
        }
        return null;
      },
    );
  }
}