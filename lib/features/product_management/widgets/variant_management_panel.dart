// lib/features/product_management/widgets/variant_management_panel.dart
import 'package:flutter/material.dart';
import '../../../core/models/variant_model.dart';
import '../../../core/services/database_service.dart';

class VariantManagementPanel extends StatelessWidget {
  final List<Variant> variants;
  final int? selectedProductId; // To know which product to add to
  final VoidCallback onDataChanged;

  const VariantManagementPanel({
    Key? key,
    required this.variants,
    required this.selectedProductId,
    required this.onDataChanged,
  }) : super(key: key);

  // --- Show Add/Edit Dialog (for Variant) ---
  void _showVariantDialog(BuildContext context, {Variant? variant}) {
    final _nameController = TextEditingController(text: variant?.name ?? '');
    final _priceController = TextEditingController(text: variant?.price.toString() ?? '');
    final _formKey = GlobalKey<FormState>();
    final bool isEditing = variant != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Modifier la variante' : 'Ajouter une variante'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Variant Name ---
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom (ex: 1L, Demi, 250g)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer un nom';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Variant Price ---
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
                  final price = double.parse(_priceController.text);

                  if (isEditing) {
                    await DatabaseService.instance.updateVariant(
                      variant.id, name, price,
                    );
                  } else {
                    await DatabaseService.instance.createVariant(
                      selectedProductId!, name, price,
                    );
                  }
                  onDataChanged(); // Reload just the variants list
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
  void _showDeleteConfirmDialog(BuildContext context, Variant variant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la variante "${variant.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseService.instance.deleteVariant(variant.id);
              onDataChanged(); // Reload variants list
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
      color: Theme.of(context).scaffoldBackgroundColor.withAlpha(100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Title Bar ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Variantes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: 'Ajouter une variante',
                // Disable 'Add' if no product is selected
                onPressed: selectedProductId == null
                    ? null
                    : () => _showVariantDialog(context),
              ),
            ],
          ),
          const Divider(),

          // --- List of Variants ---
          Expanded(
            child: selectedProductId == null
                ? const Center(child: Text('Veuillez sélectionner un produit pour voir ses variantes.'))
                : variants.isEmpty
                ? const Center(child: Text('Aucune variante pour ce produit.'))
                : ListView.builder(
              itemCount: variants.length,
              itemBuilder: (context, index) {
                final variant = variants[index];
                return Card(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  child: ListTile(
                    title: Text(variant.name),
                    subtitle: Text(
                      '${variant.price.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                          onPressed: () => _showVariantDialog(context, variant: variant),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _showDeleteConfirmDialog(context, variant),
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