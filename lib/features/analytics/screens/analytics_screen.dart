// lib/features/analytics/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/analytics/sales_summary.dart';
import '../../../core/models/analytics/hourly_sales.dart';
import '../../../core/models/analytics/top_seller.dart';
import '../../../core/models/user_model.dart';
import '../widgets/stat_card.dart';
import '../widgets/hourly_sales_chart.dart';
import '../widgets/top_sellers_list.dart';
import '../widgets/cloture_dialog.dart';
import '../../../common/theme/app_theme.dart'; // <-- CORRECTION: Import manquant ajouté

class AnalyticsScreen extends StatefulWidget {
  final User adminUser;
  const AnalyticsScreen({Key? key, required this.adminUser}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<SalesSummary> _summaryFuture;
  late Future<List<HourlySale>> _hourlySalesFuture;
  late Future<List<TopSeller>> _topSellersFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _summaryFuture = DatabaseService.instance.getTodaySalesSummary();
      _hourlySalesFuture = DatabaseService.instance.getTodaySalesByHour();
      _topSellersFuture = DatabaseService.instance.getTopSellingProducts(limit: 5);
    });
  }

  void _showClotureDialog() {
    showDialog(
      context: context,
      builder: (context) => ClotureDialog(adminUser: widget.adminUser),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Statistiques du Jour",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  // --- BOUTON DE CLÔTURE ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calculate, size: 18),
                    label: const Text("Clôture de Caisse"),
                    onPressed: _showClotureDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor, // <- This line caused the error
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadData,
                    tooltip: "Actualiser les données",
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Rangée 1: Cartes de Statut ---
          FutureBuilder<SalesSummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ));
              }
              if (!snapshot.hasData) return const Center(child: Text("Aucune donnée."));

              final summary = snapshot.data!;
              return Row(
                children: [
                  StatCard(
                    titre: "Total des Ventes",
                    valeur: "${summary.totalRevenue.toStringAsFixed(2)} DZD",
                    icone: Icons.attach_money,
                    couleur: Colors.green,
                  ),
                  const SizedBox(width: 24),
                  StatCard(
                    titre: "Commandes",
                    valeur: summary.totalOrders.toString(),
                    icone: Icons.receipt_long,
                    couleur: Colors.blue,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // --- Rangée 2: Graphique et Top Produits ---
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: FutureBuilder<List<HourlySale>>(
                    future: _hourlySalesFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      if (snapshot.data!.isEmpty) return const Center(child: Text("Aucune vente aujourd'hui."));
                      return HourlySalesChart(salesData: snapshot.data!);
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: FutureBuilder<List<TopSeller>>(
                    future: _topSellersFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      if (snapshot.data!.isEmpty) return const Center(child: Text("Aucun produit vendu."));
                      return TopSellersList(topSellers: snapshot.data!);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}