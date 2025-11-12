// lib/features/product_management/widgets/product_management_panel.dart
import 'package:flutter/material.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/database_service.dart';

class ProductManagementPanel extends StatelessWidget {
  final List<Product> products;
  final Future<List<Category>> categoriesFuture; // To populate dropdown
  final VoidCallback onDataChanged;

  const ProductManagementPanel({
    Key? key,
    required this.products,
    required this.categoriesFuture,
    required this.onDataChanged,
  }) : super(key: key);

  // --- Show Add/Edit Dialog ---
  void _showProductDialog(BuildContext context, List<Category> categories, {Product? product}) {
    final _nameController = TextEditingController(text: product?.name ?? '');
    final _priceController = TextEditingController(text: product?.price.toString() ?? '');
    int? _selectedCategoryId = product?.categoryId;
    final _formKey = GlobalKey<FormState>();
    final bool isEditing = product != null;

    if (categories.isEmpty) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: const Text('Vous devez d\'abord créer une catégorie avant d\'ajouter un produit.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))
            ],
          ));
      return;
    }

    // Set default category if not editing
    if (!isEditing) {
      _selectedCategoryId = categories.first.id;
    }

    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to update the dropdown inside the dialog
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Name ---
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nom du produit'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Veuillez entrer un nom';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- Price ---
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Prix (€)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Veuillez entrer un prix';
                          if (double.tryParse(value) == null) return 'Veuillez entrer un nombre valide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- Category ---
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        items: categories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateInDialog(() {
                              _selectedCategoryId = value;
                            });
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Catégorie'),
                        validator: (value) {
                          if (value == null) return 'Veuillez choisir une catégorie';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final name = _nameController.text;
                      final price = double.parse(_priceController.text);

                      if (isEditing) {
                        await DatabaseService.instance.updateProduct(
                          product.id, name, price, _selectedCategoryId!,
                        );
                      } else {
                        await DatabaseService.instance.createProduct(
                          name, price, _selectedCategoryId!,
                        );
                      }
                      onDataChanged(); // Reload data
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(isEditing ? 'Mettre à jour' : 'Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Show Delete Confirmation ---
  void _showDeleteConfirmDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le produit "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseService.instance.deleteProduct(product.id);
              onDataChanged(); // Reload data
              Navigator.of(context).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Title Bar ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Produits',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              // We need to load categories before we can add a product
              FutureBuilder<List<Category>>(
                future: categoriesFuture,
                builder: (context, snapshot) {
                  return IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    tooltip: 'Ajouter un produit',
                    onPressed: () {
                      final categories = snapshot.data ?? [];
                      _showProductDialog(context, categories);
                    },
                  );
                },
              ),
            ],
          ),
          const Divider(),

          // --- List of Products ---
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('Aucun produit trouvé.'))
                : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text('${product.price.toStringAsFixed(2)} €'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                          onPressed: () async {
                            // We must have the category list to show the dialog
                            final categories = await categoriesFuture;
                            _showProductDialog(context, categories, product: product);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _showDeleteConfirmDialog(context, product),
                        ),
                      ],
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