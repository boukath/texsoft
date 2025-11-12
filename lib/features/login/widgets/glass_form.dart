// lib/features/login/widgets/glass_form.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/role_model.dart';
import 'login_textfield.dart';
import '../../../features/admin_panel/screens/admin_screen.dart';
import '../../../features/pos_grid/screens/pos_screen.dart';

class GlassForm extends StatefulWidget {
  const GlassForm({Key? key}) : super(key: key);

  @override
  State<GlassForm> createState() => _GlassFormState();
}

class _GlassFormState extends State<GlassForm> {
  // Controllers to get text from fields
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Get text from controllers
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    // Call the database to validate
    final User? user = await DatabaseService.instance.validateLogin(username, password);

    // --- UPDATED NAVIGATION LOGIC ---
    if (user != null) {
      // User is valid, check role and navigate
      if (!mounted) return; // Check if widget is still visible

      if (user.role == UserRole.admin) {
        // Navigate to Admin Panel
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminScreen(adminUser: user),
          ),
        );
      } else {
        // Navigate to main POS screen for Cashier
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PosScreen(loggedInUser: user),
          ),
        );
      }

    } else {
      // Failed login
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur ou mot de passe incorrect.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                // We pass the controller to our custom text field
                LoginTextField(
                  controller: _usernameController,
                  label: 'Nom d\'utilisateur',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                LoginTextField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 40),

                // Button is now part of this widget
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleLogin, // Call our login function
                    child: const Text('Se connecter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}