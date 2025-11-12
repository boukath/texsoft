// lib/core/services/database_service.dart
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io'; // For Directory
import 'dart:convert'; // For utf8
import 'package:crypto/crypto.dart'; // For sha256
import 'package:sqflite/sqflite.dart'; // --- THIS IS THE FIX FOR ERROR 3 ---

// Model Imports
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final String path = join(appSupportDir.path, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreateDB,
    );
  }

  Future<void> _onCreateDB(Database db, int version) async {
    // --- 1. Create User Tables ---
    await db.execute('''
      CREATE TABLE Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        hashedPassword TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // --- 2. Create Default Users ---
    String defaultAdminPass = 'admin';
    String hashedAdminPass = _hashPassword(defaultAdminPass);
    await db.insert('Users', {
      'username': 'admin',
      'hashedPassword': hashedAdminPass,
      'role': userRoleToString(UserRole.admin),
    });

    String defaultCashierPass = '1234';
    String hashedCashierPass = _hashPassword(defaultCashierPass);
    await db.insert('Users', {
      'username': 'caissier',
      'hashedPassword': hashedCashierPass,
      'role': userRoleToString(UserRole.cashier),
    });

    // --- 3. Create Product & Category Tables ---
    await _createProductTables(db);
  }

  Future<void> _createProductTables(Database db) async {
    // Categories
    await db.execute('''
      CREATE TABLE Categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Products
    await db.execute('''
      CREATE TABLE Products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        price REAL NOT NULL,
        categoryId INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES Categories (id)
      )
    ''');

    // Default Data
    int catBoissonsId = await db.insert('Categories', {'name': 'Boissons'});
    int catSandwichsId = await db.insert('Categories', {'name': 'Sandwichs'});
    int catDessertsId = await db.insert('Categories', {'name': 'Desserts'});

    await db.insert('Products', {'name': 'Coca-Cola', 'price': 2.50, 'categoryId': catBoissonsId});
    await db.insert('Products', {'name': 'Eau Minérale', 'price': 1.50, 'categoryId': catBoissonsId});
    await db.insert('Products', {'name': 'Sandwich Poulet', 'price': 5.50, 'categoryId': catSandwichsId});
    await db.insert('Products', {'name': 'Tarte au Citron', 'price': 3.50, 'categoryId': catDessertsId});
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ===================================================================
  // --- USER METHODS ---
  // ===================================================================

  Future<User?> validateLogin(String username, String password) async {
    final db = await instance.database;
    final String hashedPassword = _hashPassword(password);
    final List<Map<String, dynamic>> maps = await db.query(
      'Users',
      where: 'username = ? AND hashedPassword = ?',
      whereArgs: [username, hashedPassword],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<bool> createUser(String username, String password, UserRole role) async {
    final existingUser = await getUserByUsername(username);
    if (existingUser != null) return false;
    final db = await instance.database;
    final String hashedPassword = _hashPassword(password);
    await db.insert('Users', {
      'username': username,
      'hashedPassword': hashedPassword,
      'role': userRoleToString(role),
    });
    return true;
  }

  Future<void> deleteUser(int id) async {
    final db = await instance.database;
    await db.delete('Users', where: 'id = ?', whereArgs: [id]);
  }

  // ===================================================================
  // --- POS METHODS ---
  // ===================================================================

  Future<List<Category>> getCategories() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Products',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // ===================================================================
  // --- ADMIN CATEGORY CRUD METHODS ---
  // ===================================================================

  Future<void> createCategory(String name) async {
    final db = await instance.database;
    await db.insert('Categories', {'name': name});
  }

  Future<void> updateCategory(int id, String newName) async {
    final db = await instance.database;
    await db.update('Categories', {'name': newName}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await instance.database;
    await db.delete('Categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getProductCountForCategory(int categoryId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM Products WHERE categoryId = ?',
      [categoryId],
    );
    // --- THIS LINE IS NOW FIXED ---
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ===================================================================
  // --- ADMIN PRODUCT CRUD METHODS ---
  // ===================================================================

  Future<void> createProduct(String name, double price, int categoryId) async {
    final db = await instance.database;
    await db.insert('Products', {
      'name': name,
      'price': price,
      'categoryId': categoryId,
    });
  }

  Future<void> updateProduct(int id, String newName, double newPrice, int newCategoryId) async {
    final db = await instance.database;
    await db.update(
      'Products',
      {'name': newName, 'price': newPrice, 'categoryId': newCategoryId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteProduct(int id) async {
    final db = await instance.database;
    await db.delete('Products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }
}