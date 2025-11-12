// lib/features/pos_grid/screens/pos_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/cart_item_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/variant_model.dart'; // <-- Need this
import '../../../core/models/user_model.dart';
import '../../../core/models/role_model.dart';
import '../../../core/services/database_service.dart';
import '../widgets/cart_panel.dart';
import '../widgets/category_tabs.dart';
import '../widgets/product_grid.dart';

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
    _categoriesFuture = DatabaseService.instance.getCategories();
    final categories = await _categoriesFuture;

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

  // --- THIS IS THE NEW LOGIC FOR TAPPING A PRODUCT ---
  void _onProductTapped(Product product) async {
    // 1. Fetch variants for this product
    final variants = await DatabaseService.instance.getVariantsForProduct(product.id);

    if (variants.isEmpty) {
      // No variants found (should not happen, but good to check)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune variante trouvée pour ce produit.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (variants.length == 1) {
      // 2. If only one variant, add it directly (no pop-up)
      _addVariantToCart(product, variants.first);
    } else {
      // 3. If multiple variants, show a selection dialog
      _showVariantSelectionDialog(product, variants);
    }
  }

  void _addVariantToCart(Product product, Variant variant) {
    setState(() {
      // Check if this *exact variant* is already in cart
      final existingItemIndex = _cart.indexWhere(
              (item) => item.variant.id == variant.id
      );

      if (existingItemIndex != -1) {
        // If yes, increment quantity
        _cart[existingItemIndex].quantity++;
      } else {
        // If no, add new CartItem
        // --- FIX: This is the line that had the error ---
        _cart.add(CartItem(product: product, variant: variant));
      }
    });
  }

  void _showVariantSelectionDialog(Product product, List<Variant> variants) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choisir une variante pour: ${product.name}'),
          content: Container(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: variants.length,
              itemBuilder: (context, index) {
                final variant = variants[index];
                return ListTile(
                  title: Text(variant.name),
                  trailing: Text('${variant.price.toStringAsFixed(2)} €'),
                  onTap: () {
                    _addVariantToCart(product, variant);
                    Navigator.of(context).pop(); // Close the dialog
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }
  // --- END OF NEW LOGIC ---

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
          // --- Left Side: Product Selection ---
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

                // --- Product Grid ---
                Expanded(
                  child: _isLoadingProducts
                      ? const Center(child: CircularProgressIndicator())
                      : ProductGrid(
                    products: _products,
                    onProductTapped: _onProductTapped,
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1),

          // --- Right Side: Cart ---
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