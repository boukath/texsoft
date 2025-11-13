// lib/features/product_management/widgets/category_management_panel.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart'; // Need this to list printers
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

  void _showCategoryDialog(BuildContext context, {Category? category}) async {
    final _nameController = TextEditingController(text: category?.name ?? '');
    final _formKey = GlobalKey<FormState>();
    final bool isEditing = category != null;

    // Fetch available printers
    final List<Printer> printers = await Printing.listPrinters();
    // Add a "No Print" option
    String? _selectedPrinter = category?.targetPrinter;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateInDialog) {
              return AlertDialog(
                title: Text(isEditing ? 'Modifier la catégorie' : 'Ajouter une catégorie'),
                content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Veuillez entrer un nom';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // --- Printer Selection Dropdown ---
                      DropdownButtonFormField<String?>(
                        value: _selectedPrinter,
                        decoration: const InputDecoration(
                          labelText: 'Imprimante Cuisine',
                          helperText: 'Laissez vide pour ne pas imprimer (ex: Boissons)',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                              value: null,
                              child: Text("Ne pas imprimer en cuisine")
                          ),
                          ...printers.map((p) => DropdownMenuItem<String?>(
                            value: p.name,
                            child: Text(p.name),
                          )).toList(),
                        ],
                        onChanged: (value) {
                          setStateInDialog(() {
                            _selectedPrinter = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final name = _nameController.text;
                        if (isEditing) {
                          // Updated DatabaseService to handle the new parameter
                          await DatabaseService.instance.updateCategory(category!.id, name, _selectedPrinter);
                        } else {
                          await DatabaseService.instance.createCategory(name, _selectedPrinter);
                        }
                        onDataChanged();
                        Navigator.pop(context);
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

  // ... (delete dialog and build method remain largely the same, just calling _showCategoryDialog) ...
  // For brevity, I'm including the build method to ensure the file is complete-ish

  void _showDeleteConfirmDialog(BuildContext context, Category category) async {
    final productCount = await DatabaseService.instance.getProductCountForCategory(category.id);
    if (productCount > 0) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Suppression impossible'),
          content: Text('Cette catégorie contient $productCount produits.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Confirmer'),
          content: Text('Supprimer "${category.name}" ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await DatabaseService.instance.deleteCategory(category.id);
                onDataChanged();
                Navigator.pop(c);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Catégories', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () => _showCategoryDialog(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final bool isSelected = category.id == selectedCategoryId;
                return Card(
                  color: isSelected ? Colors.blueAccent.withOpacity(0.3) : null,
                  child: ListTile(
                    title: Text(category.name),
                    subtitle: category.targetPrinter != null
                        ? Text("🖨️ ${category.targetPrinter}", style: const TextStyle(fontSize: 12, color: Colors.grey))
                        : null,
                    onTap: () => onCategorySelected(category.id),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCategoryDialog(context, category: category)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteConfirmDialog(context, category)),
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