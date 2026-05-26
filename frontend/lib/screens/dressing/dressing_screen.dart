import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/garment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garment_provider.dart';
import '../../services/firebase_storage_display_url.dart';
import '../../widgets/garment_card.dart';
import '../../widgets/dressing_category_chips_row.dart';
import '../../widgets/dressing_category_filters_bar.dart';
import '../../widgets/garment_detail_sheet.dart';
import '../../widgets/add_garment_sheet.dart';
import '../../widgets/async_error_state.dart';
import '../../widgets/loading_shimmer_grid.dart';
import '../../utils/dressing_garment_filters.dart';

class DressingScreen extends ConsumerStatefulWidget {
  const DressingScreen({super.key});

  @override
  ConsumerState<DressingScreen> createState() => _DressingScreenState();
}

class _DressingScreenState extends ConsumerState<DressingScreen> {
  String _selectedCategory = '';
  final Set<String> _prefetchedUrls = <String>{};
  final TextEditingController _nameFilterController = TextEditingController();
  String _nameFilter = '';
  String _brandFilter = '';
  String _colorFilter = '';

  @override
  void dispose() {
    _nameFilterController.dispose();
    super.dispose();
  }

  void _setCategory(String key) {
    setState(() {
      _selectedCategory = key;
      _nameFilter = '';
      _nameFilterController.clear();
      _brandFilter = '';
      _colorFilter = '';
    });
  }

  void _prefetchGarmentImages(List<GarmentModel> garments) {
    if (!mounted) return;
    for (final g in garments) {
      final urls = g.imageUrls.isNotEmpty
          ? g.imageUrls
          : (g.imageUrl.isNotEmpty ? [g.imageUrl] : const <String>[]);
      for (final raw in urls) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) continue;
        if (!_prefetchedUrls.add(trimmed)) continue;
        // ignore: discarded_futures
        () async {
          try {
            final resolved = await resolveFirebaseStorageDisplayUrl(trimmed);
            if (!mounted) return;
            await precacheImage(
              CachedNetworkImageProvider(resolved),
              context,
              onError: (_, __) {},
            );
          } catch (_) {}
        }();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).uid;
    final garmentsAsync = ref.watch(garmentsProvider(uid));

    garmentsAsync.whenData(_prefetchGarmentImages);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Mon Dressing', style: AppTextStyles.heading2),
              ),
              const SizedBox(height: 20),
              DressingCategoryChipsRow(
                selectedCategory: _selectedCategory,
                onCategorySelected: _setCategory,
              ),
              if (_selectedCategory.isNotEmpty) ...[
                const SizedBox(height: 10),
                DressingCategoryFiltersBar(
                  nameController: _nameFilterController,
                  brandFilter: _brandFilter,
                  colorFilter: _colorFilter,
                  garmentsForOptions: garmentsAsync.valueOrNull
                          ?.where((g) => g.category == _selectedCategory)
                          .toList() ??
                      const [],
                  onNameChanged: (v) => setState(() => _nameFilter = v),
                  onBrandChanged: (v) => setState(() => _brandFilter = v ?? ''),
                  onColorChanged: (v) => setState(() => _colorFilter = v ?? ''),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: garmentsAsync.when(
                  data: (garments) {
                    final byCat = _selectedCategory.isEmpty
                        ? garments
                        : garments
                            .where((g) => g.category == _selectedCategory)
                            .toList();
                    final filtered = _applyLocalFilters(byCat);
                    if (filtered.isEmpty) {
                      final noFilters = _nameFilter.trim().isEmpty &&
                          _brandFilter.isEmpty &&
                          _colorFilter.isEmpty;
                      final hasItemsInCat = byCat.isNotEmpty;
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.checkroom, size: 72, color: AppColors.textHint.withOpacity(0.3)),
                            const SizedBox(height: 20),
                            Text(
                              hasItemsInCat && !noFilters
                                  ? 'Aucun résultat'
                                  : 'Aucun vêtement',
                              style: AppTextStyles.bodySecondary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasItemsInCat && !noFilters
                                  ? 'Essaie un autre nom, marque ou couleur.'
                                  : 'Ajoute ton premier vêtement !',
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                            if (!hasItemsInCat && noFilters) ...[
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: _showAddGarmentSheet,
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Ajouter un vêtement'),
                              ),
                            ],
                          ],
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final garment = filtered[i];
                        final card = GarmentCard(
                          garment: garment,
                          onTap: () => _showGarmentDetails(garment),
                        );
                        if (i > 11) return card;
                        return card
                            .animate()
                            .fadeIn(
                              duration: 90.ms,
                              delay: (10 * i).ms,
                            )
                            .slideY(
                              begin: 0.03,
                              end: 0,
                              duration: 90.ms,
                              delay: (10 * i).ms,
                              curve: Curves.easeOut,
                            );
                      },
                    );
                  },
                  loading: () => const LoadingShimmerGrid(),
                  error: (e, _) => AsyncErrorState(
                        onRetry: () => ref.invalidate(garmentsProvider(uid)),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 16),
        child: Semantics(
          label: 'Ajouter un vêtement',
          button: true,
          child: FloatingActionButton.extended(
          heroTag: 'dressing_fab',
          tooltip: 'Ajouter un vêtement',
          backgroundColor: AppColors.accent,
          elevation: 6,
          onPressed: () => _showAddGarmentSheet(),
          icon: const Icon(Icons.add, color: AppColors.white, size: 24),
          label: const Text('Ajouter', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
        ),
        ),
      ),
    );
  }

  List<GarmentModel> _applyLocalFilters(List<GarmentModel> list) {
    if (_selectedCategory.isEmpty) return list;
    return applyDressingGarmentFilters(
      list: list,
      nameFilter: _nameFilter,
      brandFilter: _brandFilter,
      colorFilter: _colorFilter,
    );
  }

  void _showGarmentDetails(GarmentModel garment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GarmentDetailSheet(
        garment: garment,
        onEdit: () {
          Navigator.pop(context);
          _showEditGarmentSheet(garment);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(garment).then((confirmed) {
            if (confirmed == true) {
              final uid = ref.read(authServiceProvider).uid;
              ref.read(garmentNotifierProvider.notifier).deleteGarment(uid, garment.id);
            }
          });
        },
      ),
    );
  }

  void _showAddGarmentSheet() {
    pushAddGarmentRoute(context);
  }

  void _showEditGarmentSheet(GarmentModel garment) {
    pushAddGarmentRoute(context, garment: garment);
  }

  Future<bool?> _confirmDelete(GarmentModel garment) async {
    return await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicateur de glissement
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Icône de suppression
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Supprimer ce vêtement ?',
                  style: AppTextStyles.heading3.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '"${garment.name}"',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.divider, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
