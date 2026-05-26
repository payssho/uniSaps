import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/categories.dart';
import '../models/garment_model.dart';
import 'garment_thumbnail.dart';

/// Bottom sheet grille 3 colonnes — même UI que [CreationScreen] lors du choix d'une pièce.
Future<GarmentModel?> showGarmentPickerGridSheet(
  BuildContext context, {
  required String categoryKey,
  required List<GarmentModel> garments,
  String? selectedGarmentId,
}) {
  return showModalBottomSheet<GarmentModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.textHint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              categoryLabel(categoryKey),
              style: AppTextStyles.heading3,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: garments.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun vêtement dans cette catégorie',
                      style: AppTextStyles.bodySecondary,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: garments.length,
                    itemBuilder: (_, i) {
                      final g = garments[i];
                      final isSelected = selectedGarmentId == g.id;
                      return GestureDetector(
                        onTap: () => Navigator.pop(ctx, g),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.accent : AppColors.divider,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    child: GarmentThumbnail(
                                      garment: g,
                                      categoryKey: categoryKey,
                                      width: double.infinity,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      g.name,
                                      style: const TextStyle(fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: AppColors.white,
                                    ),
                                  ),
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
    ),
  );
}
