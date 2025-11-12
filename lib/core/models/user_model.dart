// lib/core/models/user_model.dart
import 'role_model.dart';

class User {
  final int? id;
  final String username;
  final String hashedPassword; // We only store the hashed password
  final UserRole role;

  User({
    this.id,
    required this.username,
    required this.hashedPassword,
    required this.role,
  });

  // Helper to convert our User object to a Map for the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'hashedPassword': hashedPassword,
      'role': userRoleToString(role), // Store the French string
    };
  }

  // Helper to convert a Map from the database to a User object
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      hashedPassword: map['hashedPassword'],
      role: roleFromString(map['role']), // Convert string back to enum
    );
  }
}