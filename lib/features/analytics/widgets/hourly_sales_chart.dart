// lib/features/analytics/widgets/hourly_sales_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/models/analytics/hourly_sales.dart';
import '../../../common/theme/app_theme.dart';

class HourlySalesChart extends StatelessWidget {
  final List<HourlySale> salesData;

  const HourlySalesChart({Key? key, required this.salesData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Trouver la vente max pour définir la hauteur Y du graphique
    final double maxY = salesData.fold(0.0, (max, e) => e.total > max ? e.total : max) * 1.2; // 20% de marge

    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ventes par Heure (Aujourd'hui)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text("${value.toInt()} DZD", style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // value est l'index 0, 1, 2...
                        final index = value.toInt();
                        if (index < salesData.length) {
                          // Affiche 1 heure sur 2 pour éviter la surcharge
                          if (index % 2 == 0) {
                            return Text(salesData[index].hour, style: const TextStyle(fontSize: 10));
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    // --- FIX IS HERE ---
                    // 'tooltipBgColor' est renommé 'getTooltipColor'
                    getTooltipColor: (barChartGroupData) {
                      return AppTheme.textDark;
                    },
                    // --- END FIX ---
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final sale = salesData[groupIndex];
                      return BarTooltipItem(
                        "${sale.hour}\n",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: "${sale.total.toStringAsFixed(2)} DZD",
                            style: const TextStyle(color: AppTheme.primaryColor),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                barGroups: salesData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final sale = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: sale.total,
                        color: AppTheme.primaryColor,
                        width: 15,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}