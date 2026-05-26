import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/categories.dart';
import '../models/garment_model.dart';
import '../providers/auth_provider.dart';
import 'garment_colors_wrap.dart';
import 'garment_photo_carousel.dart';
import 'app_bottom_sheet.dart';
import 'garment_category_glyph.dart';

enum GarmentDetailMode { owner, readOnly }

class GarmentDetailSheet extends ConsumerWidget {
  final GarmentModel garment;
  final GarmentDetailMode mode;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GarmentDetailSheet({
    super.key,
    required this.garment,
    this.mode = GarmentDetailMode.owner,
    this.onEdit,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required GarmentModel garment,
    GarmentDetailMode mode = GarmentDetailMode.owner,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GarmentDetailSheet(
        garment: garment,
        mode: mode,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mode == GarmentDetailMode.readOnly) {
      return _buildShell(context, garment);
    }

    final uid = ref.watch(authServiceProvider).uid;
    final firestoreService = ref.watch(firestoreServiceProvider);

    return StreamBuilder<GarmentModel?>(
      stream: firestoreService.garmentStream(uid, garment.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _loadingShell();
        }
        return _buildShell(context, snapshot.data ?? garment);
      },
    );
  }

  Widget _loadingShell() {
    return const AppBottomSheet(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildShell(BuildContext context, GarmentModel current) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: _buildBody(current),
            ),
          ),
          if (mode == GarmentDetailMode.owner &&
              onEdit != null &&
              onDelete != null) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: AppColors.accent,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        label: const Text(
                          'Modifier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Supprimer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ] else if (mode == GarmentDetailMode.readOnly) ...[
            SizedBox(height: 24 + bottomInset),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(GarmentModel g) {
    final imageUrls = g.imageUrls.isNotEmpty
        ? g.imageUrls
        : (g.imageUrl.isNotEmpty ? [g.imageUrl] : <String>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GarmentPhotoCarousel(
              imageUrls: imageUrls,
              category: g.category,
              height: 280,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GarmentCategoryGlyph(
                          categoryKey: g.category,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          categoryLabel(g.category),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (g.timesWorn > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${g.timesWorn}x porté',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                g.name.isNotEmpty ? g.name : 'Sans nom',
                style: AppTextStyles.heading2.copyWith(fontSize: 24),
              ),
              if (g.brand.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  g.brand,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (g.colors.isNotEmpty) ...[
                const SizedBox(height: 12),
                GarmentColorsWrap(colors: g.colors),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
