// lib/features/analytics/widgets/top_sellers_list.dart
import 'package:flutter/material.dart';
import '../../../core/models/analytics/top_seller.dart';
import '../../../common/theme/app_theme.dart';

class TopSellersList extends StatelessWidget {
  final List<TopSeller> topSellers;

  const TopSellersList({Key? key, required this.topSellers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Produits Populaires",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: topSellers.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = topSellers[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    "${item.totalSold} ventes",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}