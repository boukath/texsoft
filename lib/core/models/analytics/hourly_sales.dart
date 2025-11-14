// lib/core/models/analytics/hourly_sales.dart

// Pour les graphiques : Ventes par Heure
class HourlySale {
  final String hour; // ex: "13:00"
  final double total;

  HourlySale({
    required this.hour,
    required this.total,
  });
}