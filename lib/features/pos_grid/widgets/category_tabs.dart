// lib/features/pos_grid/widgets/category_tabs.dart
import 'package:flutter/material.dart';
import '../../../core/models/category_model.dart';

class CategoryTabs extends StatelessWidget {
  final List<Category> categories;
  final int? selectedCategoryId;
  final Function(int) onCategorySelected;

  const CategoryTabs({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final bool isSelected = category.id == selectedCategoryId;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ChoiceChip(
              label: Text(category.name),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(category.id);
                }
              },
              backgroundColor: Colors.white.withOpacity(0.1),
              selectedColor: Colors.blueAccent,
              shape: StadiumBorder(
                side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
      ),
    );
  }
}