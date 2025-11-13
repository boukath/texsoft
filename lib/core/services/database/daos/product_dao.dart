// lib/core/services/database/daos/product_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../models/product_model.dart';
import '../../../models/variant_model.dart';
import '../database_helper.dart';
import '../../image_service.dart';

class ProductDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // --- Products ---
  Future<List<Product>> getAllProducts() async {
    final db = await _db;
    final maps = await db.query('Products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await _db;
    final maps = await db.query('Products', where: 'categoryId = ?', whereArgs: [categoryId]);
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProductById(int id) async {
    final db = await _db;
    final maps = await db.query('Products', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Product.fromMap(maps.first);
    return null;
  }

  Future<int> createProduct(String name, int categoryId, String? imagePath) async {
    final db = await _db;
    return await db.insert('Products', {
      'name': name,
      'categoryId': categoryId,
      'imagePath': imagePath,
    });
  }

  Future<void> updateProduct(int id, String newName, int newCategoryId, String? newImagePath) async {
    final db = await _db;
    await db.update('Products', {
      'name': newName,
      'categoryId': newCategoryId,
      'imagePath': newImagePath,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteProduct(int id) async {
    final db = await _db;
    // Retrieve product first to delete image
    final maps = await db.query('Products', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final product = Product.fromMap(maps.first);
      if (product.imagePath != null) {
        await ImageService.instance.deleteImage(product.imagePath);
      }
    }
    await db.delete('Products', where: 'id = ?', whereArgs: [id]);
  }

  // --- Variants ---
  Future<List<Variant>> getVariantsForProduct(int productId) async {
    final db = await _db;
    final maps = await db.query('Variants', where: 'productId = ?', whereArgs: [productId]);
    return List.generate(maps.length, (i) => Variant.fromMap(maps[i]));
  }

  Future<void> createVariant(int productId, String name, double price) async {
    final db = await _db;
    await db.insert('Variants', {'productId': productId, 'name': name, 'price': price});
  }

  Future<void> updateVariant(int id, String newName, double newPrice) async {
    final db = await _db;
    await db.update('Variants', {'name': newName, 'price': newPrice}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteVariant(int id) async {
    final db = await _db;
    await db.delete('Variants', where: 'id = ?', whereArgs: [id]);
  }
}