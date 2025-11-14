// lib/core/models/analytics/sales_summary.dart

// Un simple objet pour contenir les totaux d'aujourd'hui
class SalesSummary {
  final double totalRevenue;
  final int totalOrders;

  SalesSummary({
    required this.totalRevenue,
    required this.totalOrders,
  });
}