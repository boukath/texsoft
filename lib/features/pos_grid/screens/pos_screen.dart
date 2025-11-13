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

import '../widgets/sidebar_navigation.dart';
import '../widgets/pos_category_list.dart';
import '../widgets/pos_product_card.dart';
import '../widgets/order_summary_panel.dart';
import '../../orders/screens/orders_screen.dart';

class PosScreen extends StatefulWidget {
  final User loggedInUser;
  const PosScreen({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  int _selectedIndex = 1;
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

  void _onProductTapped(Product product) async {
    final variants = await DatabaseService.instance.getVariantsForProduct(product.id);
    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune variante trouvée.')));
      return;
    }
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

  void _increment(CartItem item) => setState(() => item.quantity++);
  void _decrement(CartItem item) => setState(() {
    if (item.quantity > 1) item.quantity--; else _cart.remove(item);
  });
  void _remove(CartItem item) => setState(() => _cart.remove(item));
  void _clear() => setState(() => _cart.clear());
  double get _totalPrice => _cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  void _showVariantSelectionDialog(Product product, List<Variant> variants) {
    showDialog(context: context, builder: (c) => AlertDialog(
        title: Text(product.name),
        content: SizedBox(width: double.minPositive, child: ListView(shrinkWrap: true, children: variants.map((v) => ListTile(
            title: Text(v.name), trailing: Text("${v.price} DZD"),
            onTap: () { _addVariantToCart(product, v); Navigator.pop(c); }
        )).toList())),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Annuler"))]
    ));
  }

  void _onPay() async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    try {
      await DatabaseService.instance.createOrder(widget.loggedInUser.id!, _cart, _totalPrice);
      if(!mounted) return;
      Navigator.pop(context);
      showDialog(context: context, builder: (c) => AlertDialog(
          title: const Text("Succès"), content: const Text("Commande enregistrée !"),
          actions: [TextButton(onPressed: () { Navigator.pop(c); _clear(); }, child: const Text("OK"))]
      ));
    } catch (e) {
      if(!mounted) return;
      Navigator.pop(context);
      showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Erreur"), content: Text(e.toString())));
    }
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 1: // Menu View
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Tableau de bord", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                            Text("${DateTime.now().toString().split(' ')[0]}", style: const TextStyle(color: AppTheme.textLight)),
                          ],
                        ),
                        Container(
                          width: 300,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: const TextField(decoration: InputDecoration(border: InputBorder.none, hintText: "Rechercher...", icon: Icon(Icons.search))),
                        ),
                      ],
                    ),
                  ),
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
                            if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: LinearProgressIndicator()));
                            if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();
                            return PosCategoryList(categories: snapshot.data!, selectedCategoryId: _selectedCategoryId, onCategorySelected: _loadProducts);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.8, crossAxisSpacing: 20, mainAxisSpacing: 20),
                              itemCount: _products.length,
                              itemBuilder: (context, index) => PosProductCard(product: _products[index], onTap: () => _onProductTapped(_products[index])),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            OrderSummaryPanel(cart: _cart, onClearCart: _clear, onPay: _onPay, onIncrement: _increment, onDecrement: _decrement, onRemove: _remove, totalPrice: _totalPrice),
          ],
        );

      case 2: // Orders History View
        return const OrdersScreen(); // Removed 'Expanded' here, handled in parent

      default:
        return const Center(child: Text("Page en construction"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          SidebarNavigation(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              if (index == -1) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
              } else {
                setState(() => _selectedIndex = index);
              }
            },
          ),
          // --- FIX: Wrapped content in Expanded ---
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}