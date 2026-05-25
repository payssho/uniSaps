import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../models/outfit_model.dart';
import '../models/garment_model.dart';
import 'garment_category_glyph.dart';

class OutfitCard extends StatelessWidget {
  final OutfitModel outfit;
  final Map<String, GarmentModel> garmentCache;
  final VoidCallback? onTap;

  const OutfitCard({
    super.key,
    required this.outfit,
    required this.garmentCache,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = outfit.garments.entries
        .where((e) => e.value.isNotEmpty && garmentCache.containsKey(e.value))
        .toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.graphite.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    outfit.name.isEmpty ? 'Outfit' : outfit.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (outfit.timesWorn > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${outfit.timesWorn}x',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((e) {
                final g = garmentCache[e.value]!;
                return _GarmentChip(garment: g);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GarmentChip extends StatelessWidget {
  final GarmentModel garment;

  const _GarmentChip({required this.garment});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: garment.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: garment.imageUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 36,
                    height: 36,
                    color: AppColors.divider,
                    child: Center(
                      child: GarmentCategoryGlyph(
                        categoryKey: garment.category,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              garment.name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
