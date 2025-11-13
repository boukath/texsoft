// lib/features/product_management/screens/product_management_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/variant_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/csv_import_service.dart'; // <-- Import the new service
import '../widgets/category_management_panel.dart';
import '../widgets/product_management_panel.dart';
import '../widgets/variant_management_panel.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
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

  Future<void> _reloadData() async {
    setState(() { _isLoading = true; });

    final categories = await DatabaseService.instance.getCategories();
    final products = await DatabaseService.instance.getAllProducts();

    setState(() {
      _categories = categories;
      _products = products;

      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.any((c) => c.id == _selectedCategoryId)
            ? _selectedCategoryId
            : _categories.first.id;
      } else {
        _selectedCategoryId = null;
      }

      _updateSelectedProduct();
      _isLoading = false;
    });
  }

  // --- Import Logic ---
  Future<void> _handleCsvImport() async {
    setState(() { _isLoading = true; });

    // Call the service
    final message = await CsvImportService.instance.importMenuFromCsv();

    // Show result
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: message.startsWith("Success") ? Colors.green : Colors.red,
        ),
      );
    }

    // Refresh UI
    await _reloadData();
  }

  void _onCategorySelected(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _updateSelectedProduct();
    });
  }

  void _onProductSelected(int productId) {
    setState(() {
      _selectedProductId = productId;
      _loadVariantsForProduct(productId);
    });
  }

  void _updateSelectedProduct() {
    final filteredProducts = _products.where((p) => p.categoryId == _selectedCategoryId).toList();

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

  Future<void> _loadVariantsForProduct(int productId) async {
    // Don't set global loading here to avoid flickering the whole screen
    final variants = await DatabaseService.instance.getVariantsForProduct(productId);
    setState(() {
      _variants = variants;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((p) => p.categoryId == _selectedCategoryId).toList();

    return Column(
      children: [
        // --- Header Bar ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                  "Gestion du Menu",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleCsvImport,
                icon: const Icon(Icons.upload_file),
                label: const Text("Importer CSV"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Distinctive color
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // --- Main Content (The 3 Panels) ---
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
            children: [
              // Panel 1: Category
              Expanded(
                flex: 1,
                child: CategoryManagementPanel(
                  categories: _categories,
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: _onCategorySelected,
                  onDataChanged: _reloadData,
                ),
              ),
              const VerticalDivider(width: 1),

              // Panel 2: Product
              Expanded(
                flex: 1,
                child: ProductManagementPanel(
                  products: filteredProducts,
                  selectedProductId: _selectedProductId,
                  onProductSelected: _onProductSelected,
                  onDataChanged: _reloadData,
                  allCategories: _categories,
                  selectedCategoryId: _selectedCategoryId,
                ),
              ),
              const VerticalDivider(width: 1),

              // Panel 3: Variant
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
          ),
        ),
      ],
    );
  }
}