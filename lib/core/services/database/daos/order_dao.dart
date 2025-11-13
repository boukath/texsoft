// lib/core/services/database/daos/order_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../models/order_model.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/order_item_model.dart';
import '../database_helper.dart';

class OrderDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

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
}