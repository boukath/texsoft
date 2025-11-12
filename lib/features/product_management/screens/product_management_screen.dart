// lib/features/product_management/screens/product_management_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/database_service.dart';
import '../widgets/category_management_panel.dart'; // We will create this
import '../widgets/product_management_panel.dart'; // We will create this

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  // We need to load both lists
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  // A single function to refresh all data on the screen
  void _reloadData() {
    setState(() {
      _categoriesFuture = DatabaseService.instance.getCategories();
      _productsFuture = DatabaseService.instance.getAllProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // --- Panel 1: Category Management ---
        Expanded(
          flex: 1,
          child: FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }
              final categories = snapshot.data ?? [];

              return CategoryManagementPanel(
                categories: categories,
                onDataChanged: _reloadData, // Pass the reload function
              );
            },
          ),
        ),

        const VerticalDivider(width: 1),

        // --- Panel 2: Product Management ---
        Expanded(
          flex: 2,
          child: FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }
              final products = snapshot.data ?? [];

              return ProductManagementPanel(
                products: products,
                // We pass the category list to the product panel
                // so the "Add/Edit" dialog can show a category dropdown
                categoriesFuture: _categoriesFuture,
                onDataChanged: _reloadData, // Pass the reload function
              );
            },
          ),
        ),
      ],
    );
  }
}