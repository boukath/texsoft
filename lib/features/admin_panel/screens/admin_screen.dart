// lib/features/admin_panel/screens/admin_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../widgets/user_management_tab.dart'; // This is the content of the first tab
import '../../product_management/screens/product_management_screen.dart'; // This is the content of the second tab

class AdminScreen extends StatefulWidget {
  final User adminUser;
  const AdminScreen({Key? key, required this.adminUser}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

// We need 'TickerProviderStateMixin' for the tab animation
class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panneau d\'administration'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        // --- This is the TabBar ---
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people_outline),
              text: 'Gestion des utilisateurs',
            ),
            Tab(
              icon: Icon(Icons.fastfood_outlined),
              text: 'Gestion des produits',
            ),
          ],
        ),
      ),
      // --- This shows the content for the selected tab ---
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: User Management
          UserManagementTab(adminUser: widget.adminUser),

          // Tab 2: Product Management
          ProductManagementScreen(),
        ],
      ),
    );
  }
}