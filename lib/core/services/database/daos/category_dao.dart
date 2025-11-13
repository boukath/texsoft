// lib/core/services/database/daos/category_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../models/category_model.dart';
import '../database_helper.dart';

class CategoryDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<Category>> getCategories() async {
    final db = await _db;
    final maps = await db.query('Categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  // Updated to accept printer name
  Future<void> createCategory(String name, String? targetPrinter) async {
    final db = await _db;
    await db.insert('Categories', {
      'name': name,
      'targetPrinter': targetPrinter
    });
  }

  // Updated to accept printer name
  Future<void> updateCategory(int id, String newName, String? targetPrinter) async {
    final db = await _db;
    await db.update(
        'Categories',
        {'name': newName, 'targetPrinter': targetPrinter},
        where: 'id = ?',
        whereArgs: [id]
    );
  }

  // ... (deleteCategory and getProductCountForCategory remain the same) ...
  Future<void> deleteCategory(int id) async {
    final db = await _db;
    await db.delete('Categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getProductCountForCategory(int categoryId) async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) FROM Products WHERE categoryId = ?', [categoryId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}