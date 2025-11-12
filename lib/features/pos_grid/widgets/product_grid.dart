// lib/features/pos_grid/widgets/product_grid.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/product_model.dart';

class ProductGrid extends StatelessWidget {
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
      return const Center(child: Text('Aucun produit trouvé dans cette catégorie.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 1.0,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        Widget imageWidget;
        if (product.imagePath != null) {
          imageWidget = Image.file(
            File(product.imagePath!),
            fit: BoxFit.cover, // <-- Gardez BoxFit.cover pour remplir
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 40, color: Colors.white70),
              );
            },
          );
        } else {
          imageWidget = const Center(
            child: Icon(Icons.fastfood, size: 40, color: Colors.white70),
          );
        }

        return InkWell(
          onTap: () => onProductTapped(product),
          borderRadius: BorderRadius.circular(12.0),
          child: Card(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      // Assurez-vous que le widget Image est directement dans le ClipRRect
                      // et que sa taille est contrainte par l'Expanded.
                      child: Container( // Ajout d'un Container pour s'assurer que l'image remplit l'espace
                        width: double.infinity,
                        height: double.infinity,
                        child: imageWidget,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    flex: 1,
                    child: Text(
                      product.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  Expanded(
                    flex: 1,
                    child: const Text(
                      'Voir variantes',
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