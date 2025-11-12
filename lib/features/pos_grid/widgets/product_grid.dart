// lib/features/pos_grid/widgets/product_grid.dart
import 'dart:io'; // <-- AJOUTEZ CECI
import 'package:flutter/material.dart';
import '../../../core/models/product_model.dart';

class ProductGrid extends StatelessWidget {
  // ... (constructeur inchangé)
  final List<Product> products;
  final Function(Product) onProductTapped;

  const ProductGrid({
    Key? key,
    required this.products,
    required this.onProductTapped,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      // ... (inchangé)
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 1.0, // Nous gardons un ratio carré
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        // --- NOUVEAU : Widget pour l'image ou l'icône ---
        Widget imageWidget;
        if (product.imagePath != null) {
          imageWidget = Image.file(
            File(product.imagePath!),
            fit: BoxFit.cover,
            // Fallback en cas d'erreur de chargement
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 40, color: Colors.white70),
              );
            },
          );
        } else {
          // Image par défaut si aucune n'est définie
          imageWidget = const Center(
            child: Icon(Icons.fastfood, size: 40, color: Colors.white70),
          );
        }
        // --- FIN NOUVEAU ---

        return InkWell(
          onTap: () => onProductTapped(product),
          borderRadius: BorderRadius.circular(12.0),
          child: Card(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            clipBehavior: Clip.antiAlias, // <-- Important pour que l'image respecte les coins
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Pour étirer l'image
                children: [
                  // --- MODIFIÉ : Remplacement de l'icône par l'image ---
                  Expanded(
                    flex: 3, // Donne plus de place à l'image
                    child: ClipRRect( // Pour arrondir les coins de l'image
                      borderRadius: BorderRadius.circular(6.0),
                      child: imageWidget,
                    ),
                  ),
                  // --- FIN MODIFIÉ ---

                  const SizedBox(height: 8),

                  // Nom du produit
                  Expanded(
                    flex: 1, // Moins de place pour le texte
                    child: Text(
                      product.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1, // 1 ligne pour le nom
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // "Voir variantes"
                  Expanded(
                    flex: 1, // Moins de place pour le texte
                    child: const Text(
                      'Voir variantes', // "See variants"
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}