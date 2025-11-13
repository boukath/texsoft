// lib/features/pos_grid/widgets/sidebar_navigation.dart
import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';

class SidebarNavigation extends StatelessWidget {
  const SidebarNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppTheme.sidebarColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
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

          // Navigation Items (Translated)
          _buildNavItem(Icons.dashboard_outlined, "Tableau de bord", false),
          _buildNavItem(Icons.restaurant_menu, "Menu", true), // Selected
          _buildNavItem(Icons.receipt_long_outlined, "Commandes", false),
          _buildNavItem(Icons.people_outline, "Clients", false),
          _buildNavItem(Icons.analytics_outlined, "Statistiques", false),

          const Spacer(),

          _buildNavItem(Icons.settings_outlined, "Paramètres", false),
          _buildNavItem(Icons.logout, "Déconnexion", false, isLogout: true),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : (isLogout ? Colors.red : AppTheme.textLight)
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : (isLogout ? Colors.red : AppTheme.textLight),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          // Add navigation logic here later
        },
      ),
    );
  }
}