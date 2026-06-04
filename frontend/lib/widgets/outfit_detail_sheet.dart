import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/categories.dart';
import '../l10n/l10n_context.dart';
import '../models/garment_model.dart';
import '../models/outfit_model.dart';
import 'confirm_delete_dialog.dart';
import 'garment_detail_sheet.dart';
import 'garment_thumbnail.dart';
import 'storage_aware_cached_image.dart';

enum OutfitDetailMode { owner, readOnly }

/// Détail outfit unifié (mes outfits + profil ami).
class OutfitDetailSheet extends StatelessWidget {
  final OutfitModel outfit;
  final OutfitDetailMode mode;
  final Map<String, GarmentModel> garmentCache;
  final VoidCallback? onChooseToday;
  final VoidCallback? onDelete;
  /// Photo à mettre en avant (ex. souvenir tapé dans la galerie).
  final String? focusPhotoUrl;

  const OutfitDetailSheet({
    super.key,
    required this.outfit,
    required this.garmentCache,
    this.mode = OutfitDetailMode.owner,
    this.onChooseToday,
    this.onDelete,
    this.focusPhotoUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required OutfitModel outfit,
    required Map<String, GarmentModel> garmentCache,
    OutfitDetailMode mode = OutfitDetailMode.owner,
    VoidCallback? onChooseToday,
    VoidCallback? onDelete,
    String? focusPhotoUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OutfitDetailSheet(
        outfit: outfit,
        garmentCache: garmentCache,
        mode: mode,
        onChooseToday: onChooseToday,
        onDelete: onDelete,
        focusPhotoUrl: focusPhotoUrl,
      ),
    );
  }

  String get _heroUrl {
    if (focusPhotoUrl != null && focusPhotoUrl!.isNotEmpty) {
      return focusPhotoUrl!;
    }
    if (outfit.referencePhotoUrl.isNotEmpty) return outfit.referencePhotoUrl;
    if (outfit.photoUrls.isNotEmpty) return outfit.photoUrls.first;
    return '';
  }

  List<({String? slot, GarmentModel garment})> _resolvePieces() {
    final items = <({String? slot, GarmentModel garment})>[];
    final seen = <String>{};
    for (final e in outfit.garments.entries) {
      if (e.value.isEmpty) continue;
      for (final id in OutfitModel.parseGarmentSlotValue(e.value)) {
        if (seen.contains(id)) continue;
        final g = garmentCache[id];
        if (g != null) {
          seen.add(id);
          items.add((slot: e.key, garment: g));
        }
      }
    }
    if (items.isEmpty) {
      for (final id in outfit.garmentIds) {
        final g = garmentCache[id];
        if (g != null) items.add((slot: null, garment: g));
      }
    }
    return items;
  }

  void _openGarmentDetail(BuildContext context, GarmentModel g) {
    GarmentDetailSheet.show(
      context,
      garment: g,
      mode: GarmentDetailMode.readOnly,
    );
  }

  void _openPhotoFullScreen(BuildContext context, String url) {
    final size = MediaQuery.sizeOf(context);
    showDialog<void>(
      context: context,
      builder: (dCtx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black87,
        child: GestureDetector(
          onTap: () => Navigator.pop(dCtx),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: StorageAwareCachedImage(
              imageUrl: url,
              fit: BoxFit.contain,
              width: size.width,
              height: size.height * 0.75,
              preferHighQuality: true,
              loadingWidget: SizedBox(
                height: size.height * 0.5,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                ),
              ),
              errorWidget: (_, __) => const Icon(
                Icons.broken_image_outlined,
                color: AppColors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pieces = _resolvePieces();
    final showActions =
        mode == OutfitDetailMode.owner &&
        (onChooseToday != null || onDelete != null);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.textHint.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            outfit.name.isEmpty ? 'Outfit' : outfit.name,
                            style: AppTextStyles.heading3,
                          ),
                        ),
                        if (outfit.timesWorn > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Porté ${outfit.timesWorn}x',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (outfit.lastWorn.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Dernier port : ${outfit.lastWorn}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (_heroUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openPhotoFullScreen(context, _heroUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final w = constraints.maxWidth;
                                  final h = constraints.maxHeight;
                                  return StorageAwareCachedImage(
                                    imageUrl: _heroUrl,
                                    fit: BoxFit.cover,
                                    width: w,
                                    height: h,
                                    preferHighQuality: true,
                                    loadingWidget: Container(
                                      color: AppColors.surfaceVariant,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __) => Container(
                                      color: AppColors.surfaceVariant,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 40,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.photo_library_outlined,
                          size: 40,
                          color: AppColors.textHint,
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (pieces.isEmpty)
                      Text(
                        context.l10n.userProfileNoLinkedPieces,
                        style: AppTextStyles.bodySecondary,
                      )
                    else ...[
                      Text(context.l10n.signupCreatorCatalogPieces, style: AppTextStyles.heading3),
                      const SizedBox(height: 10),
                      ...pieces.map((entry) {
                        final g = entry.garment;
                        final slot = entry.slot;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openGarmentDetail(context, g),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: _pieceThumb(g),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            g.name.isNotEmpty
                                                ? g.name
                                                : 'Sans nom',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (g.brand.isNotEmpty)
                                            Text(
                                              g.brand,
                                              style: AppTextStyles.caption,
                                            ),
                                          if (slot != null &&
                                              mode == OutfitDetailMode.owner)
                                            Text(
                                              categoryLabel(slot, context.l10n),
                                              style: AppTextStyles.caption
                                                  .copyWith(fontSize: 11),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textHint,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            if (showActions)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (onChooseToday != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onChooseToday!();
                          },
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: AppColors.white,
                          ),
                          label: const Text('Choisir pour aujourd\'hui'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      if (onDelete != null && onChooseToday != null)
                        const SizedBox(height: 10),
                      if (onDelete != null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showConfirmDeleteSheet(
                              context,
                              title: 'Supprimer l\'outfit ?',
                              subtitle: 'Cette action est irréversible.',
                            );
                            if (confirm == true && context.mounted) {
                              Navigator.pop(context);
                              onDelete!();
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          label: const Text(
                            'Supprimer cet outfit',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: AppColors.error.withOpacity(0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pieceThumb(GarmentModel g) {
    return GarmentThumbnail(
      garment: g,
      categoryKey: g.category,
      width: 48,
      height: 48,
    );
  }
}
