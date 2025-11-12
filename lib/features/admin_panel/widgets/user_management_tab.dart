// lib/features/admin_panel/widgets/user_management_tab.dart
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/database_service.dart';
import 'add_user_form.dart';
import 'user_list_view.dart';

class UserManagementTab extends StatefulWidget {
  final User adminUser;
  const UserManagementTab({Key? key, required this.adminUser}) : super(key: key);

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = DatabaseService.instance.getAllUsers();
    });
  }

  Future<void> _onDeleteUser(int userId) async {
    // Prevent admin from deleting themselves
    if (userId == widget.adminUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas supprimer votre propre compte admin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await DatabaseService.instance.deleteUser(userId);
    _loadUsers(); // Refresh the list
  }

  void _onUserAdded() {
    _loadUsers(); // Refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Part 1: The User List
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Utilisateurs actuels',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<User>>(
                    future: _usersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erreur: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Aucun utilisateur trouvé.'));
                      }

                      return UserListView(
                        users: snapshot.data!,
                        currentUser: widget.adminUser,
                        onDelete: _onDeleteUser,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // A visual separator
        const VerticalDivider(width: 1),

        // Part 2: The "Add User" form
        Expanded(
          flex: 1,
          child: AddUserForm(
            onUserAdded: _onUserAdded,
          ),
        ),
      ],
    );
  }
}