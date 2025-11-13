// lib/core/models/order_item_model.dart

class OrderItemModel {
  final int? id;
  final int orderId;
  final int productId;
  final int variantId;
  final String productName; // Snapshot
  final String variantName; // Snapshot
  final double price;       // Snapshot (price at moment of sale)
  final int quantity;

  OrderItemModel({
    this.id,
    required this.orderId,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'variantId': variantId,
      'productName': productName,
      'variantName': variantName,
      'price': price,
      'quantity': quantity,
    };
  }
}