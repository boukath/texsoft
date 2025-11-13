// lib/features/pos_grid/screens/pos_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/cart_item_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/variant_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/database_service.dart';
import '../../login/screens/login_screen.dart';
import '../../../common/theme/app_theme.dart';

// Custom Widgets
import '../widgets/sidebar_navigation.dart';
import '../widgets/pos_category_list.dart';
import '../widgets/pos_product_card.dart';
import '../widgets/order_summary_panel.dart';
import '../widgets/payment_dialog.dart'; // The new payment dialog
import '../../orders/screens/orders_screen.dart'; // The history screen

class PosScreen extends StatefulWidget {
  final User loggedInUser;
  const PosScreen({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // --- Navigation State ---
  // 1 = Menu (POS), 2 = Orders (History)
  int _selectedIndex = 1;

  // --- POS Data State ---
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

  // --- Data Loading ---
  Future<void> _loadInitialData() async {
    _categoriesFuture = DatabaseService.instance.getCategories();
    final categories = await _categoriesFuture;

    // Load the first category by default if available
    if (categories.isNotEmpty) {
      _loadProducts(categories.first.id);
    } else {
      setState(() => _isLoadingProducts = false);
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

  // --- Product & Cart Logic ---
  void _onProductTapped(Product product) async {
    // Fetch variants to check if we need a selection dialog
    final variants = await DatabaseService.instance.getVariantsForProduct(product.id);

    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aucune variante trouvée pour ce produit.'),
            backgroundColor: Colors.orange
        ),
      );
      return;
    }

    // If only 1 variant, add directly. Otherwise, show dialog.
    if (variants.length == 1) {
      _addVariantToCart(product, variants.first);
    } else {
      _showVariantSelectionDialog(product, variants);
    }
  }

  void _addVariantToCart(Product product, Variant variant) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.variant.id == variant.id);

      if (existingIndex != -1) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(product: product, variant: variant));
      }
    });
  }

  void _increment(CartItem item) {
    setState(() => item.quantity++);
  }

  void _decrement(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cart.remove(item);
      }
    });
  }

  void _remove(CartItem item) {
    setState(() => _cart.remove(item));
  }

  void _clear() {
    setState(() => _cart.clear());
  }

  double get _totalPrice {
    return _cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void _showVariantSelectionDialog(Product product, List<Variant> variants) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Choisir : ${product.name}'),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: variants.length,
              itemBuilder: (context, index) {
                final variant = variants[index];
                return ListTile(
                    title: Text(variant.name),
                    trailing: Text("${variant.price.toStringAsFixed(2)} DZD"),
                    onTap: () {
                      _addVariantToCart(product, variant);
                      Navigator.pop(context);
                    }
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            )
          ],
        )
    );
  }

  // --- Payment Process ---
  void _onPay() async {
    // 1. Open the Payment Dialog first
    final bool? paymentConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PaymentDialog(totalAmount: _totalPrice),
    );

    // If cancelled, stop here
    if (paymentConfirmed != true) return;

    // 2. Show loading while saving
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 3. Save Order to Database
      await DatabaseService.instance.createOrder(
        widget.loggedInUser.id!,
        _cart,
        _totalPrice,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      // 4. Success Message & Clear Cart
      showDialog(
          context: context,
          builder: (c) => AlertDialog(
              title: const Text("Succès"),
              content: const Text("Paiement validé et commande enregistrée !"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(c);
                      _clear(); // Only clear after successful save
                    },
                    child: const Text("OK")
                )
              ]
          )
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      showDialog(
          context: context,
          builder: (c) => AlertDialog(
              title: const Text("Erreur"),
              content: Text("Erreur lors de l'enregistrement : $e"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text("OK")
                )
              ]
          )
      );
    }
  }

  // --- Main Layout Builder ---
  Widget _buildContent() {
    switch (_selectedIndex) {
      case 1: // View 1: The POS Menu
        return Row(
          children: [
            // Center: Product Grid & Categories
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                "Tableau de bord",
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)
                            ),
                            Text(
                                "${DateTime.now().toString().split(' ')[0]}",
                                style: const TextStyle(color: AppTheme.textLight)
                            ),
                          ],
                        ),
                        // Search Bar
                        Container(
                          width: 300,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12)
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Rechercher...",
                                icon: Icon(Icons.search)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Categories
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Choisir une catégorie", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Category>>(
                          future: _categoriesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(height: 100, child: Center(child: LinearProgressIndicator()));
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const SizedBox();
                            }
                            return PosCategoryList(
                              categories: snapshot.data!,
                              selectedCategoryId: _selectedCategoryId,
                              onCategorySelected: _loadProducts,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Products Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Tous les produits", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _isLoadingProducts
                                ? const Center(child: CircularProgressIndicator())
                                : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                return PosProductCard(
                                  product: _products[index],
                                  onTap: () => _onProductTapped(_products[index]),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Right: Order Summary Panel
            OrderSummaryPanel(
              cart: _cart,
              onClearCart: _clear,
              onPay: _onPay,
              onIncrement: _increment,
              onDecrement: _decrement,
              onRemove: _remove,
              totalPrice: _totalPrice,
            ),
          ],
        );

      case 2: // View 2: Orders History
        return const Expanded(child: OrdersScreen());

      default:
        return const Expanded(child: Center(child: Text("Page en construction")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          // Left Sidebar (Persistent)
          SidebarNavigation(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              if (index == -1) {
                // Logout
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (c) => const LoginScreen()),
                        (r) => false
                );
              } else {
                // Navigate
                setState(() => _selectedIndex = index);
              }
            },
          ),

          // Dynamic Content Area
          Expanded( // <--- Ensures content takes remaining space
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}