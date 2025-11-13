// lib/features/pos_grid/widgets/pos_category_list.dart
import 'package:flutter/material.dart';
import '../../../core/models/category_model.dart';
import '../../../common/theme/app_theme.dart';

class PosCategoryList extends StatelessWidget {
  final List<Category> categories;
  final int? selectedCategoryId;
  final Function(int) onCategorySelected;

  const PosCategoryList({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategoryId;

          return GestureDetector(
            onTap: () => onCategorySelected(category.id),
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFF5F7FA),
                      shape: BoxShape.circle,
                    ),
                    // You can map categories to icons later. For now, generic.
                    child: Icon(
                      Icons.lunch_dining, // Placeholder icon
                      color: isSelected ? Colors.white : AppTheme.textDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}