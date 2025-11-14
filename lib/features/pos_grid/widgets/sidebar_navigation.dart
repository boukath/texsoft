// lib/features/pos_grid/widgets/sidebar_navigation.dart
import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';
import '../../../core/models/user_model.dart'; // <-- Importez le modèle User
import '../../../core/models/role_model.dart'; // <-- Importez le modèle Role

class SidebarNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final User loggedInUser; // <-- Ajoutez l'utilisateur connecté

  const SidebarNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.loggedInUser, // <-- Ajoutez au constructeur
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Déterminez si l'utilisateur est un admin
    final bool isAdmin = loggedInUser.role == UserRole.admin;

    return Container(
      width: 250,
      color: AppTheme.sidebarColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Logo ---
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fastfood, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              const Text(
                "TexSoft",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // --- Menu Items (Pour tous) ---
          // 0: Tableau de bord
          _buildNavItem(0, Icons.dashboard_outlined, "Tableau de bord"),
          // 1: Menu (Caisse)
          _buildNavItem(1, Icons.restaurant_menu, "Menu"),
          // 2: Commandes (Historique)
          _buildNavItem(2, Icons.receipt_long_outlined, "Commandes"),

          // --- Section Admin (Conditionnelle) ---
          if (isAdmin)
            _buildNavItem(3, Icons.people_outline, "Clients"),
          if (isAdmin)
            _buildNavItem(4, Icons.analytics_outlined, "Statistiques"),

          const Spacer(),

          // --- Section Admin (Conditionnelle) ---
          if (isAdmin)
            _buildNavItem(5, Icons.settings_outlined, "Paramètres"),

          // --- Déconnexion (Pour tous) ---
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == selectedIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textLight
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () => onItemSelected(index),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text(
        "Déconnexion",
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        // Signale au parent de se déconnecter
        onItemSelected(-1);
      },
    );
  }
}