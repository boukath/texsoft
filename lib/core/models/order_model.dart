// lib/core/models/order_model.dart

class OrderModel {
  final int? id;
  final int userId; // The cashier who made the sale
  final DateTime date;
  final double totalPrice;

  OrderModel({
    this.id,
    required this.userId,
    required this.date,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'totalPrice': totalPrice,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'],
      userId: map['userId'],
      date: DateTime.parse(map['date']),
      totalPrice: map['totalPrice'],
    );
  }
}