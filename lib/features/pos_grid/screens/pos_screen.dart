// lib/features/pos_grid/screens/pos_screen.dart
import 'package:flutter/material.dart';

// --- CORE MODEL IMPORTS ---
import '../../../core/models/cart_item_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/role_model.dart';
import '../../../core/services/database_service.dart';

// --- WIDGET IMPORTS ---
import '../widgets/cart_panel.dart';
import '../widgets/category_tabs.dart';
import '../widgets/product_grid.dart'; // <-- THE IMPORT

class PosScreen extends StatefulWidget {
  final User loggedInUser;

  const PosScreen({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // State variables
  late Future<List<Category>> _categoriesFuture;
  List<Product> _products = [];
  List<CartItem> _cart = [];
  int? _selectedCategoryId;
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // 1. Get categories
    _categoriesFuture = DatabaseService.instance.getCategories();
    final categories = await _categoriesFuture;

    // 2. If categories exist, load products for the first one
    if (categories.isNotEmpty) {
      _loadProducts(categories.first.id);
    } else {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadProducts(int categoryId) async {
    setState(() {
      _isLoadingProducts = true;
      _selectedCategoryId = categoryId;
    });

    final products = await DatabaseService.instance.getProductsByCategory(categoryId);

    setState(() {
      _products = products;
      _isLoadingProducts = false;
    });
  }

  void _onCategorySelected(int categoryId) {
    _loadProducts(categoryId);
  }

  void _onProductTapped(Product product) {
    setState(() {
      // Check if product is already in cart
      final existingItemIndex = _cart.indexWhere(
              (item) => item.product.id == product.id
      );

      if (existingItemIndex != -1) {
        // If yes, increment quantity
        _cart[existingItemIndex].quantity++;
      } else {
        // If no, add new CartItem
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _onClearCart() {
    setState(() {
      _cart.clear();
    });
  }

  void _onPay() {
    // Logic for payment goes here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paiement'),
        content: const Text('Le paiement a été effectué avec succès!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onClearCart();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Point de Vente - ${widget.loggedInUser.username} (${userRoleToString(widget.loggedInUser.role)})'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              // We will implement a proper logout later
            },
          )
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                FutureBuilder<List<Category>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LinearProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Aucune catégorie trouvée.'));
                    }
                    return CategoryTabs(
                      categories: snapshot.data!,
                      selectedCategoryId: _selectedCategoryId,
                      onCategorySelected: _onCategorySelected,
                    );
                  },
                ),

                Expanded(
                  child: _isLoadingProducts
                      ? const Center(child: CircularProgressIndicator())
                      : ProductGrid( // <-- This is the line (168)
                    products: _products,
                    onProductTapped: _onProductTapped,
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1),

          Expanded(
            flex: 1,
            child: CartPanel(
              cart: _cart,
              onClearCart: _onClearCart,
              onPay: _onPay,
            ),
          ),
        ],
      ),
    );
  }
}