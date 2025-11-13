// lib/features/pos_grid/widgets/order_summary_panel.dart
import 'package:flutter/material.dart';
import '../../../core/models/cart_item_model.dart';
import '../../../common/theme/app_theme.dart';

class OrderSummaryPanel extends StatelessWidget {
  final List<CartItem> cart;
  final VoidCallback onClearCart;
  final VoidCallback onPay;
  final Function(CartItem) onIncrement;
  final Function(CartItem) onDecrement;
  final Function(CartItem) onRemove;
  final double totalPrice;

  const OrderSummaryPanel({
    Key? key,
    required this.cart,
    required this.onClearCart,
    required this.onPay,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.totalPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: double.infinity, // <--- THIS FIXES THE ERROR (Forces full height)
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Customer Info Section ---
          const Text("Informations Client", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Client Comptoir", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Table 01", style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Current Order Title ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Commande actuelle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: onClearCart
              ),
            ],
          ),
          const SizedBox(height: 10),

          // --- Cart Items List ---
          // This Expanded caused the crash because the parent didn't have a height.
          // Now that Container has height: double.infinity, this works!
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text("Le panier est vide"))
                : ListView.separated(
              itemCount: cart.length,
              separatorBuilder: (c, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = cart[index];
                return Row(
                  children: [
                    // Item Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item.product.name} - ${item.variant.name}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${item.variant.price.toStringAsFixed(2)} DZD",
                            style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Controls
                    Row(
                      children: [
                        _circleBtn(Icons.remove, () => onDecrement(item), color: Colors.grey.shade200, iconColor: Colors.black),
                        const SizedBox(width: 8),
                        Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        _circleBtn(Icons.add, () => onIncrement(item), color: AppTheme.primaryColor, iconColor: Colors.white),
                      ],
                    )
                  ],
                );
              },
            ),
          ),

          const Divider(),
          const SizedBox(height: 16),

          // --- Totals ---
          _buildSummaryRow("Sous-total", "${totalPrice.toStringAsFixed(2)} DZD"),
          const SizedBox(height: 8),
          _buildSummaryRow("TVA (19%)", "${(totalPrice * 0.19).toStringAsFixed(2)} DZD"),
          const SizedBox(height: 16),
          const Divider(endIndent: 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                "${(totalPrice * 1.19).toStringAsFixed(2)} DZD",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Pay Button ---
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: cart.isEmpty ? null : onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                shadowColor: AppTheme.primaryColor.withOpacity(0.4),
              ),
              child: const Text("Payer (Espèces)", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {required Color color, required Color iconColor}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: iconColor),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textLight)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}