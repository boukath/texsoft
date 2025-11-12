// lib/features/product_management/widgets/product_management_panel.dart
import 'package:flutter/material.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/services/database_service.dart';

class ProductManagementPanel extends StatelessWidget {
  final List<Product> products;
  final int? selectedProductId;
  final Function(int) onProductSelected;
  final VoidCallback onDataChanged;
  final List<Category> allCategories;
  final int? selectedCategoryId; // The currently selected category

  const ProductManagementPanel({
    Key? key,
    required this.products,
    required this.selectedProductId,
    required this.onProductSelected,
    required this.onDataChanged,
    required this.allCategories,
    required this.selectedCategoryId,
  }) : super(key: key);

  // --- Show Add/Edit Dialog (for Base Product) ---
  void _showProductDialog(BuildContext context, {Product? product}) {
    final _nameController = TextEditingController(text: product?.name ?? '');
    final _formKey = GlobalKey<FormState>();
    final bool isEditing = product != null;

    // Set the initial category in the dropdown
    int? _dialogSelectedCategoryId = isEditing
        ? product.categoryId
        : (allCategories.any((c) => c.id == selectedCategoryId)
        ? selectedCategoryId
        : null);

    // Error if no categories exist
    if (allCategories.isEmpty) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: const Text('Vous devez d\'abord créer une catégorie avant d\'ajouter un produit.'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
          ));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateInDialog) {
              return AlertDialog(
                title: Text(isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
                content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nom du produit'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Veuillez entrer un nom';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _dialogSelectedCategoryId,
                        items: allCategories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateInDialog(() {
                              _dialogSelectedCategoryId = value;
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
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final name = _nameController.text;

                        if (isEditing) {
                          await DatabaseService.instance.updateProduct(
                            product.id, name, _dialogSelectedCategoryId!,
                          );
                        } else {
                          await DatabaseService.instance.createProduct(
                            name, _dialogSelectedCategoryId!,
                          );
                        }
                        onDataChanged(); // Reload all data
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(isEditing ? 'Mettre à jour' : 'Créer'),
                  ),
                ],
              );
            }
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
        content: Text('Voulez-vous vraiment supprimer le produit "${product.name}" ?\n\nTOUTES ses variantes (ex: 1L, 0.5L) seront aussi supprimées.'),
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
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: 'Ajouter un produit',
                // Disable 'Add' if no category is selected or no categories exist
                onPressed: selectedCategoryId == null
                    ? null
                    : () => _showProductDialog(context),
              ),
            ],
          ),
          const Divider(),

          // --- List of Products ---
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('Aucun produit dans cette catégorie.'))
                : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final bool isSelected = product.id == selectedProductId;

                return Card(
                  color: isSelected
                      ? Colors.blueAccent.withOpacity(0.3)
                      : Theme.of(context).inputDecorationTheme.fillColor,
                  child: ListTile(
                    title: Text(product.name),
                    onTap: () => onProductSelected(product.id),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                          onPressed: () => _showProductDialog(context, product: product),
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