// lib/core/models/cart_item_model.dart
import 'variant_model.dart';
import 'product_model.dart';

class CartItem {
  final Product product; // The base product (e.g., "Coca-Cola")
  final Variant variant; // The specific variant (e.g., "1L")
  int quantity;

  CartItem({
    required this.product,
    required this.variant,
    this.quantity = 1
  });

  double get totalPrice => variant.price * quantity;
}