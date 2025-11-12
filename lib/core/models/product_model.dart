// lib/core/models/product_model.dart

class Product {
  final int id;
  final String name;
  final double price;
  final int categoryId;
  // We can add more fields later, like 'imagePath'

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      categoryId: map['categoryId'],
    );
  }
}