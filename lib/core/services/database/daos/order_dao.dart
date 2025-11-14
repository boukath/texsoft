// lib/core/services/database/daos/order_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../models/order_model.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/order_item_model.dart';
import '../database_helper.dart';

// Import the new analytics models
import '../../../models/analytics/sales_summary.dart';
import '../../../models/analytics/hourly_sales.dart';
import '../../../models/analytics/top_seller.dart';

class OrderDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // --- Fonctions existantes (pas de changement) ---
  Future<void> createOrder(int userId, List<CartItem> cartItems, double totalPrice) async {
    final db = await _db;
    await db.transaction((txn) async {
      int orderId = await txn.insert('Orders', {
        'userId': userId,
        'date': DateTime.now().toIso8601String(),
        'totalPrice': totalPrice,
      });

      for (var item in cartItems) {
        await txn.insert('OrderItems', {
          'orderId': orderId,
          'productId': item.product.id,
          'variantId': item.variant.id,
          'productName': item.product.name,
          'variantName': item.variant.name,
          'price': item.variant.price,
          'quantity': item.quantity,
        });
      }
    });
  }

  Future<List<OrderModel>> getAllOrders() async {
    final db = await _db;
    final result = await db.query('Orders', orderBy: 'date DESC');
    return result.map((map) => OrderModel.fromMap(map)).toList();
  }

  Future<List<OrderItemModel>> getOrderItems(int orderId) async {
    final db = await _db;
    final result = await db.query('OrderItems', where: 'orderId = ?', whereArgs: [orderId]);

    return result.map((map) => OrderItemModel(
      id: map['id'] as int?,
      orderId: map['orderId'] as int,
      productId: map['productId'] as int,
      variantId: map['variantId'] as int,
      productName: map['productName'] as String,
      variantName: map['variantName'] as String,
      price: map['price'] as double,
      quantity: map['quantity'] as int,
    )).toList();
  }

  // --- NOUVELLES FONCTIONS POUR STATISTIQUES ---

  // Helper pour obtenir la date d'aujourd'hui au format AAAA-MM-JJ
  String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // Fonction 1 : Obtenir les chiffres clés (Total Ventes, Total Commandes)
  Future<SalesSummary> getTodaySalesSummary() async {
    final db = await _db;
    final String today = _getTodayDateString();

    // Exécute les deux requêtes en parallèle pour plus d'efficacité
    final revenueFuture = db.rawQuery(
        'SELECT SUM(totalPrice) as total FROM Orders WHERE DATE(date) = ?',
        [today]
    );
    final countFuture = db.rawQuery(
        'SELECT COUNT(id) as count FROM Orders WHERE DATE(date) = ?',
        [today]
    );

    final results = await Future.wait([revenueFuture, countFuture]);

    final revenueResult = results[0].first;
    final countResult = results[1].first;

    final double totalRevenue = (revenueResult['total'] as double?) ?? 0.0;
    final int totalOrders = (countResult['count'] as int?) ?? 0;

    return SalesSummary(totalRevenue: totalRevenue, totalOrders: totalOrders);
  }

  // Fonction 2 : Obtenir les Ventes par Heure (pour les graphiques)
  Future<List<HourlySale>> getTodaySalesByHour() async {
    final db = await _db;
    final String today = _getTodayDateString();

    final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
      SELECT STRFTIME('%H:00', date) as hour, SUM(totalPrice) as total
      FROM Orders
      WHERE DATE(date) = ?
      GROUP BY STRFTIME('%H:00', date)
      ORDER BY hour ASC
      ''',
        [today]
    );

    return maps.map((map) => HourlySale(
        hour: map['hour'] as String,
        total: map['total'] as double
    )).toList();
  }

  // Fonction 3 : Obtenir les Produits les plus vendus (Top 5)
  Future<List<TopSeller>> getTopSellingProducts(int limit) async {
    final db = await _db;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
      SELECT productName, SUM(quantity) as totalSold
      FROM OrderItems
      GROUP BY productName
      ORDER BY totalSold DESC
      LIMIT ?
      ''',
        [limit]
    );

    return maps.map((map) => TopSeller(
        productName: map['productName'] as String,
        totalSold: map['totalSold'] as int
    )).toList();
  }
}