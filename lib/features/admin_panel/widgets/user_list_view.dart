// lib/features/admin_panel/widgets/user_list_view.dart
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/role_model.dart'; // --- FIX: Added this import

class UserListView extends StatelessWidget {
  final List<User> users;
  final User currentUser; // The logged-in admin
  final Function(int) onDelete;

  const UserListView({
    Key? key,
    required this.users,
    required this.currentUser,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final bool isSelf = user.id == currentUser.id;

        return Card(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Icon(
              // --- FIX: This line will now work ---
              user.role == UserRole.admin ? Icons.shield_outlined : Icons.person_outline,
            ),
            title: Text(
              '${user.username} ${isSelf ? "(Vous)" : ""}', // French: (You)
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // --- FIX: This line will now work ---
            subtitle: Text(userRoleToString(user.role)),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: isSelf ? Colors.grey.withOpacity(0.5) : Colors.redAccent,
              ),
              // Disable the button if the user is trying to delete themselves
              onPressed: isSelf ? null : () => onDelete(user.id!),
            ),
          ),
        );
      },
    );
  }
}