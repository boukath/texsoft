// lib/features/product_management/widgets/product_management_panel.dart
import 'dart:io'; // <-- N'oubliez pas cet import
import 'package:flutter/material.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/image_service.dart'; // <-- N'oubliez pas cet import

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

    // --- NOUVEAU : Gérer l'état de l'image dans le dialogue ---
    File? _pickedImage;
    String? _existingImagePath = product?.imagePath;
    // --- FIN NOUVEAU ---

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
        // Nous utilisons StatefulBuilder pour gérer l'état du dialogue
        return StatefulBuilder(
            builder: (context, setStateInDialog) {
              return AlertDialog(
                title: Text(isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
                content: Form(
                  key: _formKey,
                  child: SingleChildScrollView( // <-- Pour éviter le débordement
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- NOUVEAU : Zone de l'image ---
                        Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.black26,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // L'image (si elle existe)
                              if (_pickedImage != null)
                                Image.file(_pickedImage!, fit: BoxFit.cover)
                              else if (_existingImagePath != null)
                                Image.file(File(_existingImagePath!), fit: BoxFit.cover,
                                  // Gérer les erreurs si le fichier est corrompu/supprimé
                                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40),
                                )
                              else
                                const Center(child: Icon(Icons.image, size: 40)),

                              // Bouton de modification
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final file = await ImageService.instance.pickImage();
                                    if (file != null) {
                                      setStateInDialog(() {
                                        _pickedImage = file;
                                      });
                                    }
                                  },
                                  child: Text(_existingImagePath != null || _pickedImage != null ? 'Changer' : 'Ajouter'),
                                ),
                              )
                            ],
                          ),
                        ),
                        // --- FIN NOUVEAU ---
                        const SizedBox(height: 16),
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
                        String? finalImagePath = _existingImagePath;

                        if (isEditing) {
                          // --- LOGIQUE DE MISE À JOUR ---
                          if (_pickedImage != null) {
                            finalImagePath = await ImageService.instance.saveImage(
                              _pickedImage!,
                              product!.id, // L'ID existe déjà
                              _existingImagePath,
                            );
                          }
                          await DatabaseService.instance.updateProduct(
                            product!.id,
                            name,
                            _dialogSelectedCategoryId!,
                            finalImagePath, // Mettre à jour avec le nouveau chemin
                          );
                        } else {
                          // --- LOGIQUE DE CRÉATION ---
                          // 1. Créer le produit avec une image null
                          int newProductId = await DatabaseService.instance.createProduct(
                            name,
                            _dialogSelectedCategoryId!,
                            null, // L'image vient après
                          );

                          // 2. Si une image a été choisie, la sauvegarder
                          if (_pickedImage != null) {
                            finalImagePath = await ImageService.instance.saveImage(
                              _pickedImage!,
                              newProductId, // Utiliser le nouvel ID
                              null, // Pas d'ancienne image
                            );

                            // 3. Mettre à jour le produit avec le chemin de l'image
                            await DatabaseService.instance.updateProduct(
                              newProductId,
                              name,
                              _dialogSelectedCategoryId!,
                              finalImagePath,
                            );
                          }
                        }
                        onDataChanged(); // Recharger toutes les données
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
        // C'est ici que la faute de frappe a été corrigée :
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
                    // --- NOUVEAU : Afficher l'image ---
                    leading: Container(
                      width: 40,
                      height: 40,
                      // Ajout d'un ClipRRect pour des bords arrondis
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: (product.imagePath != null)
                            ? Image.file(
                          File(product.imagePath!),
                          fit: BoxFit.cover, // Assure que l'image remplit le cadre
                          errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported),
                        )
                            : const Icon(Icons.fastfood),
                      ),
                    ),
                    // --- FIN NOUVEAU ---
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