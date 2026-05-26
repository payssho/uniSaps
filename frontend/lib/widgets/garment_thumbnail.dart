import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/garment_model.dart';
import 'garment_category_glyph.dart';
import 'storage_aware_cached_image.dart';

/// Miniature vêtement avec fond visible (PNG fond transparent / détourage IA).
class GarmentThumbnail extends StatelessWidget {
  final GarmentModel? garment;
  final String categoryKey;
  final BoxFit fit;
  final double? width;
  final double? height;

  const GarmentThumbnail({
    super.key,
    this.garment,
    required this.categoryKey,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  String? get _imageUrl {
    if (garment == null) return null;
    if (garment!.imageUrls.isNotEmpty) return garment!.imageUrls.first;
    if (garment!.imageUrl.isNotEmpty) return garment!.imageUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl;
    return ClipRect(
      child: ColoredBox(
        color: AppColors.surfaceVariant,
        child: url != null
            ? StorageAwareCachedImage(
                imageUrl: url,
                fit: fit,
                width: width,
                height: height,
                loadingWidget: Center(
                  child: SizedBox(
                    width: (height ?? 28) * 0.45,
                    height: (height ?? 28) * 0.45,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __) => _glyph(),
              )
            : _glyph(),
      ),
    );
  }

  Widget _glyph() {
    return Center(
      child: GarmentCategoryGlyph(
        categoryKey: categoryKey,
        color: AppColors.textHint,
        size: (height ?? 44) * 0.55,
      ),
    );
  }
}
