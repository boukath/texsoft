// lib/features/pos_grid/widgets/product_grid.dart
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
      return const Center(
        child: Text(
          'Aucun produit dans cette catégorie.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // Adjust count for screen size
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 1.0, // Makes the tiles square
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return InkWell(
          onTap: () => onProductTapped(product),
          borderRadius: BorderRadius.circular(12.0),
          child: Card(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // We can add an Icon or Image here later
                  const Icon(Icons.fastfood, size: 40, color: Colors.white70),
                  const Spacer(),
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.price.toStringAsFixed(2)} €', // French currency
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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