// lib/features/pos_grid/widgets/sidebar_navigation.dart
import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';

class SidebarNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SidebarNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

          // --- Menu Items ---
          // 0: Dashboard (Tableau de bord)
          _buildNavItem(0, Icons.dashboard_outlined, "Tableau de bord"),
          // 1: Menu (The POS Grid)
          _buildNavItem(1, Icons.restaurant_menu, "Menu"),
          // 2: Orders (The History) - THIS IS THE NEW BUTTON
          _buildNavItem(2, Icons.receipt_long_outlined, "Commandes"),
          // 3: Clients
          _buildNavItem(3, Icons.people_outline, "Clients"),
          // 4: Analytics
          _buildNavItem(4, Icons.analytics_outlined, "Statistiques"),

          const Spacer(),

          // --- Bottom Items ---
          _buildNavItem(5, Icons.settings_outlined, "Paramètres"),
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
        // We pass -1 to signal a logout
        onItemSelected(-1);
      },
    );
  }
}