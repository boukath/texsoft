// lib/features/product_management/widgets/category_management_panel.dart
import 'package:flutter/material.dart';
import '../../../core/models/category_model.dart';
import '../../../core/services/database_service.dart';

class CategoryManagementPanel extends StatelessWidget {
  final List<Category> categories;
  final int? selectedCategoryId;
  final Function(int) onCategorySelected;
  final VoidCallback onDataChanged;

  const CategoryManagementPanel({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onDataChanged,
  }) : super(key: key);

  // --- Show Add/Edit Dialog ---
  void _showCategoryDialog(BuildContext context, {Category? category}) {
    final _nameController = TextEditingController(text: category?.name ?? '');
    final _formKey = GlobalKey<FormState>();
    final bool isEditing = category != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Modifier la catégorie' : 'Ajouter une catégorie'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
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
                    await DatabaseService.instance.updateCategory(category.id, name);
                  } else {
                    await DatabaseService.instance.createCategory(name);
                  }
                  onDataChanged(); // Reload all data on the main screen
                  Navigator.of(context).pop();
                }
              },
              child: Text(isEditing ? 'Mettre à jour' : 'Créer'),
            ),
          ],
        );
      },
    );
  }

  // --- Show Delete Confirmation ---
  void _showDeleteConfirmDialog(BuildContext context, Category category) async {
    // Check if category has products
    final productCount = await DatabaseService.instance.getProductCountForCategory(category.id);

    if (productCount > 0) {
      // If not empty, show error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Suppression impossible'),
          content: Text('Cette catégorie contient $productCount produit(s). Vous devez d\'abord supprimer ou déplacer ces produits.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // If empty, show confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Voulez-vous vraiment supprimer la catégorie "${category.name}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await DatabaseService.instance.deleteCategory(category.id);
                onDataChanged(); // Reload data
                Navigator.of(context).pop();
              },
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).scaffoldBackgroundColor.withAlpha(100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Title Bar ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catégories',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: 'Ajouter une catégorie',
                onPressed: () => _showCategoryDialog(context),
              ),
            ],
          ),
          const Divider(),

          // --- List of Categories ---
          Expanded(
            child: categories.isEmpty
                ? const Center(child: Text('Aucune catégorie trouvée.'))
                : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final bool isSelected = category.id == selectedCategoryId;

                return Card(
                  color: isSelected
                      ? Colors.blueAccent.withOpacity(0.3)
                      : Theme.of(context).inputDecorationTheme.fillColor,
                  child: ListTile(
                    title: Text(category.name),
                    onTap: () => onCategorySelected(category.id),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                          onPressed: () => _showCategoryDialog(context, category: category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _showDeleteConfirmDialog(context, category),
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