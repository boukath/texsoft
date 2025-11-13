// lib/features/pos_grid/widgets/pos_product_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/product_model.dart';
import '../../../common/theme/app_theme.dart';

class PosProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const PosProductCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Image Section ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
                      ]
                  ),
                  child: ClipOval(
                    child: product.imagePath != null
                        ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                        : Container(
                      color: AppTheme.backgroundColor,
                      child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),

            // --- Info Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Délicieux & Frais",
              style: TextStyle(color: AppTheme.textLight, fontSize: 10),
            ),

            const SizedBox(height: 12),

            // --- Price & Add Button ---
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "-- DZD", // Updated to DZD
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDark
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}