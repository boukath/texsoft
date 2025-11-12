// lib/core/models/variant_model.dart

class Variant {
  final int id;
  final int productId;
  final String name;
  final double price;

  Variant({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
  });

  factory Variant.fromMap(Map<String, dynamic> map) {
    return Variant(
      id: map['id'],
      productId: map['productId'],
      name: map['name'],
      price: map['price'],
    );
  }
}