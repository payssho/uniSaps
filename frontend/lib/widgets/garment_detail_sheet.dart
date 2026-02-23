import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/categories.dart';
import '../models/garment_model.dart';
import '../services/color_service.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';

class GarmentDetailSheet extends ConsumerWidget {
  final GarmentModel garment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GarmentDetailSheet({
    super.key,
    required this.garment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authServiceProvider).uid;
    final firestoreService = ref.watch(firestoreServiceProvider);
    
    // Utiliser un Stream direct sur le document du vêtement pour écouter les changements en temps réel
    // Cela garantit que l'imageUrl sera à jour même si elle est ajoutée après la création
    return StreamBuilder<GarmentModel?>(
      stream: firestoreService.garmentStream(uid, garment.id),
      builder: (context, snapshot) {
        // Utiliser le vêtement à jour du stream s'il existe, sinon utiliser celui passé en paramètre
        final currentGarment = snapshot.data ?? garment;
        
        // Si on est en train de charger et qu'on n'a pas encore de données, afficher un loader
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          );
        }
        
        return _buildContent(context, currentGarment);
      },
    );
  }

  Widget _buildContent(BuildContext context, GarmentModel garment) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur de glissement
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Image du vêtement
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 280,
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                  child: garment.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: garment.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, error) {
                            // Debug: afficher l'erreur dans la console
                            debugPrint('Erreur chargement image: $error');
                            debugPrint('URL image: ${garment.imageUrl}');
                            return Container(
                              color: AppColors.surfaceVariant,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    categoryIcon(garment.category),
                                    size: 60,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Image non disponible',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Icon(
                          categoryIcon(garment.category),
                          size: 60,
                          color: AppColors.textHint,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Informations du vêtement
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              categoryIcon(garment.category),
                              size: 16,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              categoryLabel(garment.category),
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
                      if (garment.timesWorn > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                '${garment.timesWorn}x porté',
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
                    garment.name,
                    style: AppTextStyles.heading2.copyWith(fontSize: 24),
                  ),
                  if (garment.brand.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      garment.brand,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (garment.colors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: garment.colors.map((colorName) {
                        final colorOption = _getColorOptionFromString(colorName);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: colorOption.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorOption.color == Colors.white ||
                                          colorOption.color == Colors.transparent
                                      ? AppColors.divider
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: colorOption.color == Colors.transparent
                                  ? Center(
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red,
                                              Colors.orange,
                                              Colors.yellow,
                                              Colors.green,
                                              Colors.blue,
                                              Colors.indigo,
                                              Colors.purple,
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              colorName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Boutons d'action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.accent, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, color: AppColors.accent, size: 20),
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
                      icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                      label: const Text(
                        'Supprimer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  ColorOption _getColorOptionFromString(String colorName) {
    final allColors = ColorService.getColors();
    return allColors.firstWhere(
      (c) => c.name.toLowerCase() == colorName.toLowerCase(),
      orElse: () => ColorOption(name: colorName, color: AppColors.textHint),
    );
  }
}
