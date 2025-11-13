// lib/core/services/database_service.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

// Imports for the specific DAOs
import 'database/database_helper.dart';
import 'database/daos/user_dao.dart';
import 'database/daos/category_dao.dart';
import 'database/daos/product_dao.dart';
import 'database/daos/order_dao.dart';

// Model Imports (needed for return types)
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/variant_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

class DatabaseService {
  // Singleton
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  // Initialize DAOs
  final _userDao = UserDao();
  final _categoryDao = CategoryDao();
  final _productDao = ProductDao();
  final _orderDao = OrderDao();

  // Expose Database (via Helper)
  Future<Database> get database => DatabaseHelper.instance.database;

  // ================= USER METHODS =================
  Future<User?> validateLogin(String u, String p) => _userDao.validateLogin(u, p);
  Future<List<User>> getAllUsers() => _userDao.getAllUsers();
  Future<bool> createUser(String u, String p, UserRole r) => _userDao.createUser(u, p, r);
  Future<void> deleteUser(int id) => _userDao.deleteUser(id);
  Future<User?> getUserByUsername(String u) => _userDao.getUserByUsername(u);

  // ================= CATEGORY METHODS =================
  Future<List<Category>> getCategories() => _categoryDao.getCategories();
  Future<void> createCategory(String name) => _categoryDao.createCategory(name);
  Future<void> updateCategory(int id, String name) => _categoryDao.updateCategory(id, name);
  Future<void> deleteCategory(int id) => _categoryDao.deleteCategory(id);
  Future<int> getProductCountForCategory(int id) => _categoryDao.getProductCountForCategory(id);

  // ================= PRODUCT & VARIANT METHODS =================
  Future<List<Product>> getAllProducts() => _productDao.getAllProducts();
  Future<List<Product>> getProductsByCategory(int id) => _productDao.getProductsByCategory(id);
  Future<Product?> getProductById(int id) => _productDao.getProductById(id);
  Future<int> createProduct(String name, int catId, String? img) => _productDao.createProduct(name, catId, img);
  Future<void> updateProduct(int id, String name, int catId, String? img) => _productDao.updateProduct(id, name, catId, img);
  Future<void> deleteProduct(int id) => _productDao.deleteProduct(id);

  Future<List<Variant>> getVariantsForProduct(int id) => _productDao.getVariantsForProduct(id);
  Future<void> createVariant(int pid, String name, double price) => _productDao.createVariant(pid, name, price);
  Future<void> updateVariant(int id, String name, double price) => _productDao.updateVariant(id, name, price);
  Future<void> deleteVariant(int id) => _productDao.deleteVariant(id);

  // ================= ORDER METHODS =================
  Future<void> createOrder(int uid, List<CartItem> items, double total) => _orderDao.createOrder(uid, items, total);
  Future<List<OrderModel>> getAllOrders() => _orderDao.getAllOrders();
  Future<List<OrderItemModel>> getOrderItems(int id) => _orderDao.getOrderItems(id);
}