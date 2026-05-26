import 'package:flutter/material.dart';
import '../core/constants/categories.dart';
import 'category_chip.dart';
import 'garment_category_glyph.dart';

/// Rangée horizontale Tout + catégories (Dressing + profil ami).
class DressingCategoryChipsRow extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const DressingCategoryChipsRow({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          CategoryChip(
            label: 'Tout',
            leadingBuilder: (c) =>
                Icon(Icons.grid_view_rounded, size: 16, color: c),
            selected: selectedCategory.isEmpty,
            onTap: () => onCategorySelected(''),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryChip(
                label: cat.label,
                leadingBuilder: (c) => GarmentCategoryGlyph(
                  categoryKey: cat.key,
                  color: c,
                  size: 16,
                ),
                selected: selectedCategory == cat.key,
                onTap: () => onCategorySelected(cat.key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
