// lib/features/admin_panel/widgets/add_user_form.dart
import 'package:flutter/material.dart';
import '../../../core/models/role_model.dart';
import '../../../core/services/database_service.dart';

class AddUserForm extends StatefulWidget {
  final VoidCallback onUserAdded;
  const AddUserForm({Key? key, required this.onUserAdded}) : super(key: key);

  @override
  State<AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Default role is Cashier
  UserRole _selectedRole = UserRole.cashier;

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      // Call our updated createUser method
      final bool success = await DatabaseService.instance.createUser(
        username,
        password,
        _selectedRole,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur créé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear the form
        _formKey.currentState!.reset();
        _usernameController.clear();
        _passwordController.clear();
        setState(() {
          _selectedRole = UserRole.cashier;
        });
        // Call the callback to refresh the list on the other side
        widget.onUserAdded();
      } else {
        // This means the username was a duplicate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce nom d\'utilisateur existe déjà.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter un utilisateur',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Username field
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom d' 'utilisateur';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un mot de passe';
                }
                if (value.length < 4) {
                  return 'Le mot de passe doit contenir au moins 4 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Role selection dropdown
            DropdownButtonFormField<UserRole>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Rôle'),
              items: UserRole.values
                  .where((role) => role != UserRole.unknown) // Don't show 'unknown'
                  .map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(userRoleToString(role)), // 'Admin' or 'Caissier'
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
            const Spacer(), // Pushes the button to the bottom

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                child: const Text('Créer l\'utilisateur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}