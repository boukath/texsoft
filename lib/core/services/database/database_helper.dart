// lib/core/services/database/database_helper.dart
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import '../../models/role_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static const _dbName = 'pos.db';
  static const _dbVersion = 3;

  // Singleton
  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final String path = join(appSupportDir.path, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreateDB,
      onUpgrade: _onUpgradeDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // --- MIGRATIONS ---
  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE Products ADD COLUMN imagePath TEXT');
      } catch (e) {
        print("Migration V2 Error: $e");
      }
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE Orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          date TEXT NOT NULL,
          totalPrice REAL NOT NULL,
          FOREIGN KEY (userId) REFERENCES Users (id)
        )
      ''');
      await db.execute('''
        CREATE TABLE OrderItems (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          orderId INTEGER NOT NULL,
          productId INTEGER NOT NULL,
          variantId INTEGER NOT NULL,
          productName TEXT NOT NULL,
          variantName TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          price REAL NOT NULL,
          FOREIGN KEY (orderId) REFERENCES Orders (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // --- CREATION ---
  Future<void> _onCreateDB(Database db, int version) async {
    // 1. Users
    await db.execute('''
      CREATE TABLE Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        hashedPassword TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // 2. Default Users
    await db.insert('Users', {
      'username': 'admin',
      'hashedPassword': hashPassword('admin'),
      'role': userRoleToString(UserRole.admin),
    });
    await db.insert('Users', {
      'username': 'caissier',
      'hashedPassword': hashPassword('1234'),
      'role': userRoleToString(UserRole.cashier),
    });

    // 3. Products & Categories
    await _createProductTables(db);

    // 4. Orders
    await db.execute('''
      CREATE TABLE Orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        date TEXT NOT NULL,
        totalPrice REAL NOT NULL,
        FOREIGN KEY (userId) REFERENCES Users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE OrderItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        variantId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        variantName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (orderId) REFERENCES Orders (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createProductTables(Database db) async {
    await db.execute('''
      CREATE TABLE Categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE Products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        categoryId INTEGER NOT NULL,
        imagePath TEXT, 
        FOREIGN KEY (categoryId) REFERENCES Categories (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE Variants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (productId) REFERENCES Products (id) ON DELETE CASCADE
      )
    ''');

    // Default Data
    int catBoissons = await db.insert('Categories', {'name': 'Boissons'});
    int catSandwichs = await db.insert('Categories', {'name': 'Sandwichs'});
    int catDesserts = await db.insert('Categories', {'name': 'Desserts'});

    int pCoca = await db.insert('Products', {'name': 'Coca-Cola', 'categoryId': catBoissons});
    int pEau = await db.insert('Products', {'name': 'Eau Minérale', 'categoryId': catBoissons});
    int pPanini = await db.insert('Products', {'name': 'Panini 3 Fromages', 'categoryId': catSandwichs});
    int pTarte = await db.insert('Products', {'name': 'Tarte au Citron', 'categoryId': catDesserts});

    await db.insert('Variants', {'productId': pCoca, 'name': '0.5L', 'price': 2.50});
    await db.insert('Variants', {'productId': pCoca, 'name': '1L', 'price': 3.50});
    await db.insert('Variants', {'productId': pEau, 'name': '50cl', 'price': 1.50});
    await db.insert('Variants', {'productId': pPanini, 'name': 'Demi', 'price': 4.00});
    await db.insert('Variants', {'productId': pPanini, 'name': 'Entier', 'price': 6.00});
    await db.insert('Variants', {'productId': pTarte, 'name': 'Part', 'price': 3.50});
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}