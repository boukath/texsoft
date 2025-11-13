// lib/features/orders/widgets/order_detail_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/order_item_model.dart';
import '../../../core/services/database_service.dart';
import '../../../common/theme/app_theme.dart';

class OrderDetailDialog extends StatelessWidget {
  final OrderModel order;

  const OrderDetailDialog({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Commande #${order.id}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                order.date.toString().split('.')[0],
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
            ],
          ),
          // Receipt Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
          ),
        ],
      ),
      content: SizedBox(
        width: 500, // Fixed width for a nice receipt look
        height: 400,
        child: FutureBuilder<List<OrderItemModel>>(
          future: DatabaseService.instance.getOrderItems(order.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erreur: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Aucun article trouvé."));
            }

            final items = snapshot.data!;

            return Column(
              children: [
                const Divider(),
                // --- Header Row ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: const [
                      Expanded(flex: 3, child: Text("Produit", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight))),
                      Expanded(flex: 1, child: Text("Prix", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight))),
                      Expanded(flex: 1, child: Text("Qté", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight))),
                      Expanded(flex: 1, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight))),
                    ],
                  ),
                ),
                const Divider(),

                // --- Items List ---
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final rowTotal = item.price * item.quantity;

                      return Row(
                        children: [
                          // Product Name & Variant
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(item.variantName, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                              ],
                            ),
                          ),
                          // Unit Price
                          Expanded(
                              flex: 1,
                              child: Text("${item.price.toStringAsFixed(2)}", textAlign: TextAlign.right)
                          ),
                          // Quantity
                          Expanded(
                              flex: 1,
                              child: Text("x${item.quantity}", textAlign: TextAlign.right)
                          ),
                          // Row Total
                          Expanded(
                              flex: 1,
                              child: Text("${rowTotal.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const Divider(),
                // --- Footer Total ---
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Payé", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        "${order.totalPrice.toStringAsFixed(2)} DZD",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Fermer"),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Placeholder for print feature
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impression en cours...")));
          },
          icon: const Icon(Icons.print, size: 18),
          label: const Text("Imprimer"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        )
      ],
    );
  }
}