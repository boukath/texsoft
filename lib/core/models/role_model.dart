// lib/core/models/role_model.dart

// We can use an enum for strong type-safety
enum UserRole {
  admin,
  cashier, // "Caissier" in French
  unknown
}

// Helper function to get the string value in French
String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'Admin';
    case UserRole.cashier:
      return 'Caissier';
    default:
      return 'Inconnu';
  }
}

// Helper function to get a role from a database string
UserRole roleFromString(String roleString) {
  if (roleString == 'Admin') return UserRole.admin;
  if (roleString == 'Caissier') return UserRole.cashier;
  return UserRole.unknown;
}