// lib/features/product_management/screens/product_management_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/variant_model.dart';
import '../../../core/services/database_service.dart';
import '../widgets/category_management_panel.dart';
import '../widgets/product_management_panel.dart';
import '../widgets/variant_management_panel.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  // --- State for the entire screen ---
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Variant> _variants = [];

  int? _selectedCategoryId;
  int? _selectedProductId;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  // --- Data Loading ---
  Future<void> _reloadData() async {
    setState(() { _isLoading = true; });

    // Fetch all categories and products
    final categories = await DatabaseService.instance.getCategories();
    final products = await DatabaseService.instance.getAllProducts();

    setState(() {
      _categories = categories;
      _products = products;

      // If a category was selected, keep it. If not, select the first one.
      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.any((c) => c.id == _selectedCategoryId)
            ? _selectedCategoryId
            : _categories.first.id;
      } else {
        _selectedCategoryId = null;
      }

      _updateSelectedProduct(); // Will filter products

      _isLoading = false;
    });
  }

  // --- State Management ---

  // When a category is tapped
  void _onCategorySelected(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _updateSelectedProduct();
    });
  }

  // When a product is tapped
  void _onProductSelected(int productId) {
    setState(() {
      _selectedProductId = productId;
      _loadVariantsForProduct(productId);
    });
  }

  // Helper to filter products and variants
  void _updateSelectedProduct() {
    final filteredProducts = _products.where((p) => p.categoryId == _selectedCategoryId).toList();

    // If a product was selected, keep it. If not, select the first one.
    if (filteredProducts.isNotEmpty) {
      _selectedProductId = filteredProducts.any((p) => p.id == _selectedProductId)
          ? _selectedProductId
          : filteredProducts.first.id;
      _loadVariantsForProduct(_selectedProductId!);
    } else {
      _selectedProductId = null;
      _variants = [];
    }
  }

  // Helper to fetch variants for the selected product
  Future<void> _loadVariantsForProduct(int productId) async {
    setState(() { _isLoading = true; }); // Show loading for variants
    final variants = await DatabaseService.instance.getVariantsForProduct(productId);
    setState(() {
      _variants = variants;
      _isLoading = false;
    });
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Filter products based on selected category
    final filteredProducts = _products.where((p) => p.categoryId == _selectedCategoryId).toList();

    return Row(
      children: [
        // --- Panel 1: Category Management ---
        Expanded(
          flex: 1,
          child: CategoryManagementPanel(
            categories: _categories,
            // --- FIX: This parameter was missing ---
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: _onCategorySelected,
            onDataChanged: _reloadData,
          ),
        ),
        const VerticalDivider(width: 1),

        // --- Panel 2: Product Management ---
        Expanded(
          flex: 1,
          child: ProductManagementPanel(
            products: filteredProducts,
            selectedProductId: _selectedProductId,
            onProductSelected: _onProductSelected,
            onDataChanged: _reloadData,
            // --- FIX: This parameter was named incorrectly ---
            allCategories: _categories,
            selectedCategoryId: _selectedCategoryId,
          ),
        ),
        const VerticalDivider(width: 1),

        // --- Panel 3: Variant Management ---
        Expanded(
          flex: 1,
          child: VariantManagementPanel(
            variants: _variants,
            selectedProductId: _selectedProductId,
            onDataChanged: () {
              if (_selectedProductId != null) {
                _loadVariantsForProduct(_selectedProductId!);
              }
            },
          ),
        ),
      ],
    );
  }
}