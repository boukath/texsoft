// lib/core/models/product_model.dart

class Product {
  final int id;
  final String name;
  final int categoryId;
  final String? imagePath; // <-- AJOUTEZ CECI

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.imagePath, // <-- AJOUTEZ CECI
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      categoryId: map['categoryId'],
      imagePath: map['imagePath'], // <-- AJOUTEZ CECI
    );
  }
}