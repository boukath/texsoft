// lib/features/pos_grid/widgets/cart_panel.dart
import 'package:flutter/material.dart';
import '../../../core/models/cart_item_model.dart';

class CartPanel extends StatelessWidget {
  final List<CartItem> cart;
  final VoidCallback onClearCart;
  final VoidCallback onPay;

  const CartPanel({
    Key? key,
    required this.cart,
    required this.onClearCart,
    required this.onPay,
  }) : super(key: key);

  // Calculate total in the widget
  double get _totalPrice {
    return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withAlpha(100),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Cart Title ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Commande', // "Order" in French
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                tooltip: 'Annuler la commande', // "Cancel order"
                onPressed: onClearCart,
              ),
            ],
          ),
          const Divider(),

          // --- Cart List ---
          Expanded(
            child: cart.isEmpty
                ? const Center(
              child: Text(
                'Le panier est vide.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];
                return ListTile(
                  // --- FIX: Show product name AND variant name ---
                  title: Text('${item.product.name} (${item.variant.name})'),
                  subtitle: Text(
                    // --- FIX: Use variant.price ---
                    'Qté: ${item.quantity}  @  ${item.variant.price.toStringAsFixed(2)} €',
                  ),
                  trailing: Text(
                    '${item.totalPrice.toStringAsFixed(2)} €',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          // --- Totals ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_totalPrice.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),

          // --- Pay Button ---
          ElevatedButton(
            onPressed: cart.isEmpty ? null : onPay, // Disable if cart is empty
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 24),
            ),
            child: const Text(
              'Payer', // "Pay" in French
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}