// lib/core/models/product_model.dart

class Product {
  final int id;
  final String name;
  final int categoryId;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      categoryId: map['categoryId'],
    );
  }
}