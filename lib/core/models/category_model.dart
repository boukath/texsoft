// lib/core/models/category_model.dart

class Category {
  final int id;
  final String name;
  final String? targetPrinter; // New: Stores the printer name (e.g., "EPSON TM-T20")

  Category({
    required this.id,
    required this.name,
    this.targetPrinter,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      targetPrinter: map['targetPrinter'],
    );
  }
}