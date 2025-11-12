// lib/core/services/database_service.dart
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io'; // For Directory
import 'dart:convert'; // For utf8
import 'package:crypto/crypto.dart'; // For sha256
import 'package:sqflite/sqflite.dart';

// Model Imports
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/variant_model.dart';
// --- NOUVEL IMPORT ---
import 'image_service.dart'; // Service pour gérer les fichiers images

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
      version: 2, // <-- MODIFIÉ : Version 2
      onCreate: _onCreateDB,
      onUpgrade: _onUpgradeDB, // <-- AJOUTÉ : Gestionnaire de migration
      // Enable foreign keys
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // --- NOUVELLE FONCTION : Migration de la DB ---
  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Si l'ancienne version est 1, ajoutez la colonne imagePath
      try {
        await db.execute('ALTER TABLE Products ADD COLUMN imagePath TEXT');
      } catch (e) {
        print("Erreur lors de la migration de la table Products: $e");
      }
    }
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

  // --- CETTE FONCTION EST MISE À JOUR ---
  Future<void> _createProductTables(Database db) async {
    // Categories Table (No change)
    await db.execute('''
      CREATE TABLE Categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Products Table (MODIFIÉ : Ajout de imagePath)
    await db.execute('''
      CREATE TABLE Products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        categoryId INTEGER NOT NULL,
        imagePath TEXT, 
        FOREIGN KEY (categoryId) REFERENCES Categories (id) ON DELETE CASCADE
      )
    ''');

    // --- NEW TABLE: Variants ---
    await db.execute('''
      CREATE TABLE Variants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (productId) REFERENCES Products (id) ON DELETE CASCADE
      )
    ''');

    // --- Insert Default Categories ---
    int catBoissonsId = await db.insert('Categories', {'name': 'Boissons'});
    int catSandwichsId = await db.insert('Categories', {'name': 'Sandwichs'});
    int catDessertsId = await db.insert('Categories', {'name': 'Desserts'});

    // --- Insert Default Products (Base) ---
    int prodCocaId = await db.insert('Products', {'name': 'Coca-Cola', 'categoryId': catBoissonsId});
    int prodEauId = await db.insert('Products', {'name': 'Eau Minérale', 'categoryId': catBoissonsId});
    int prodPaniniId = await db.insert('Products', {'name': 'Panini 3 Fromages', 'categoryId': catSandwichsId});
    int prodTarteId = await db.insert('Products', {'name': 'Tarte au Citron', 'categoryId': catDessertsId});

    // --- Insert Default Variants ---
    // Coca-Cola Variants
    await db.insert('Variants', {'productId': prodCocaId, 'name': '0.5L', 'price': 2.50});
    await db.insert('Variants', {'productId': prodCocaId, 'name': '1L', 'price': 3.50});
    // Eau Minérale Variants
    await db.insert('Variants', {'productId': prodEauId, 'name': '50cl', 'price': 1.50});
    // Panini Variants
    await db.insert('Variants', {'productId': prodPaniniId, 'name': 'Demi', 'price': 4.00});
    await db.insert('Variants', {'productId': prodPaniniId, 'name': 'Entier', 'price': 6.00});
    // Tarte Variants
    await db.insert('Variants', {'productId': prodTarteId, 'name': 'Part', 'price': 3.50});
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ===================================================================
  // --- USER METHODS (No Change) ---
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

  // ===================================================================
  // --- POS METHODS ---
  // ===================================================================

  Future<List<Category>> getCategories() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  // --- UPDATED to get base products ---
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Products',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // --- NEW: Get variants for a specific product ---
  Future<List<Variant>> getVariantsForProduct(int productId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Variants',
      where: 'productId = ?',
      whereArgs: [productId],
    );
    return List.generate(maps.length, (i) => Variant.fromMap(maps[i]));
  }

  // ===================================================================
  // --- ADMIN CATEGORY CRUD (Small Update) ---
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
    // ON DELETE CASCADE in the 'Products' table will handle deleting products.
    await db.delete('Categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- UPDATED to check Products, not Variants ---
  Future<int> getProductCountForCategory(int categoryId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM Products WHERE categoryId = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ===================================================================
  // --- ADMIN PRODUCT & VARIANT CRUD ---
  // ===================================================================

  // --- NOUVELLE MÉTHODE : Pour obtenir un produit par ID (nécessaire pour la suppression) ---
  Future<Product?> getProductById(int id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // --- Create (Base Product) ---
  // MODIFIÉ : Accepte imagePath et retourne le nouvel ID
  Future<int> createProduct(String name, int categoryId, String? imagePath) async {
    final db = await instance.database;
    return await db.insert('Products', {
      'name': name,
      'categoryId': categoryId,
      'imagePath': imagePath, // <-- AJOUTÉ
    });
  }

  // --- Update (Base Product) ---
  // MODIFIÉ : Accepte newImagePath
  Future<void> updateProduct(int id, String newName, int newCategoryId, String? newImagePath) async {
    final db = await instance.database;
    await db.update(
      'Products',
      {
        'name': newName,
        'categoryId': newCategoryId,
        'imagePath': newImagePath, // <-- AJOUTÉ
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Delete (Base Product) ---
  // MODIFIÉ : Supprime également l'image associée
  Future<void> deleteProduct(int id) async {
    final db = await instance.database;

    // 1. Récupérer le produit pour trouver son chemin d'image
    final product = await getProductById(id);

    // 2. Supprimer le produit de la DB (les variantes sont supprimées en cascade)
    await db.delete('Products', where: 'id = ?', whereArgs: [id]);

    // 3. Supprimer le fichier image du disque (après la suppression de la DB)
    if (product != null) {
      await ImageService.instance.deleteImage(product.imagePath);
    }
  }

  // --- Get ALL (Base Products) ---
  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // --- NEW: Create Variant ---
  Future<void> createVariant(int productId, String name, double price) async {
    final db = await instance.database;
    await db.insert('Variants', {
      'productId': productId,
      'name': name,
      'price': price,
    });
  }

  // --- NEW: Update Variant ---
  Future<void> updateVariant(int id, String newName, double newPrice) async {
    final db = await instance.database;
    await db.update(
      'Variants',
      {'name': newName, 'price': newPrice},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- NEW: Delete Variant ---
  Future<void> deleteVariant(int id) async {
    final db = await instance.database;
    await db.delete('Variants', where: 'id = ?', whereArgs: [id]);
  }
}