import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/garment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garment_provider.dart';
import '../../providers/personalization_provider.dart';
import '../../widgets/personalization_hint_card.dart';
import '../../services/firebase_storage_display_url.dart';
import '../../widgets/garment_card.dart';
import '../../widgets/dressing_category_chips_row.dart';
import '../../widgets/dressing_category_filters_bar.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/garment_detail_sheet.dart';
import '../../widgets/add_garment_sheet.dart';
import '../../widgets/async_error_state.dart';
import '../../widgets/loading_shimmer_grid.dart';
import '../../l10n/l10n_context.dart';
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
    final l10n = context.l10n;
    final uid = ref.watch(authServiceProvider).uid;
    final garmentsAsync = ref.watch(garmentsProvider(uid));
    final hasAnyGarment = garmentsAsync.valueOrNull?.isNotEmpty ?? false;
    final perso = ref.watch(personalizationProvider);
    final garmentCount = garmentsAsync.valueOrNull?.length ?? 0;

    garmentsAsync.whenData(_prefetchGarmentImages);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(l10n.dressingMyWardrobe, style: AppTextStyles.heading2),
              ),
              if (perso.showDressingStatsCard) ...[
                const SizedBox(height: 12),
                PersonalizationHintCard(
                  title: l10n.persoDressingStatsTitle,
                  subtitle: l10n.persoDressingStatsCount(garmentCount),
                  icon: Icons.checkroom_outlined,
                  actionLabel: l10n.persoDressingAddCta,
                  onTap: _showAddGarmentSheet,
                ),
              ],
              const SizedBox(height: 20),
              DressingCategoryChipsRow(
                selectedCategory: _selectedCategory,
                onCategorySelected: _setCategory,
              ),
              const SizedBox(height: 10),
              DressingCategoryFiltersBar(
                nameController: _nameFilterController,
                brandFilter: _brandFilter,
                colorFilter: _colorFilter,
                garmentsForOptions: _garmentsForFilterOptions(
                  garmentsAsync.valueOrNull ?? const [],
                ),
                onNameChanged: (v) => setState(() => _nameFilter = v),
                onBrandChanged: (v) => setState(() => _brandFilter = v ?? ''),
                onColorChanged: (v) => setState(() => _colorFilter = v ?? ''),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: garmentsAsync.when(
                  data: (garments) {
                    final wardrobeEmpty = garments.isEmpty;
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
                      return AppEmptyState(
                        icon: Icons.checkroom,
                        title: hasItemsInCat && !noFilters
                            ? l10n.dressingNoResults
                            : l10n.dressingNoGarments,
                        subtitle: hasItemsInCat && !noFilters
                            ? l10n.dressingTryOtherFilters
                            : l10n.dressingAddFirstGarment,
                        action: wardrobeEmpty && noFilters
                            ? _AnimatedAddGarmentButton(
                                onPressed: _showAddGarmentSheet,
                              )
                            : null,
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
      floatingActionButton: hasAnyGarment
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 16),
              child: Semantics(
                label: l10n.dressingAddGarment,
                button: true,
                child: FloatingActionButton.extended(
                  heroTag: 'dressing_fab',
                  tooltip: l10n.dressingAddGarment,
                  backgroundColor: AppColors.accent,
                  elevation: 6,
                  onPressed: _showAddGarmentSheet,
                  icon: const Icon(Icons.add, color: AppColors.white, size: 24),
                  label: Text(
                    l10n.dressingAddShort,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  List<GarmentModel> _garmentsForFilterOptions(List<GarmentModel> all) {
    if (_selectedCategory.isEmpty) return all;
    return all.where((g) => g.category == _selectedCategory).toList();
  }

  List<GarmentModel> _applyLocalFilters(List<GarmentModel> list) {
    return applyDressingGarmentFilters(
      list: list,
      nameFilter: _nameFilter,
      brandFilter: _brandFilter,
      colorFilter: _colorFilter,
    );
  }

  void _showGarmentDetails(GarmentModel garment) {
    GarmentDetailSheet.show(
      context,
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
            ref
                .read(garmentNotifierProvider.notifier)
                .deleteGarment(uid, garment.id);
          }
        });
      },
    );
  }

  void _showAddGarmentSheet() {
    pushAddGarmentRoute(context);
  }

  void _showEditGarmentSheet(GarmentModel garment) {
    pushAddGarmentRoute(context, garment: garment);
  }

  Future<bool?> _confirmDelete(GarmentModel garment) {
    return showConfirmDeleteSheet(
      context,
      title: context.l10n.garmentDeleteConfirmTitle,
      subtitle: '"${garment.name}"',
    );
  }
}

class _AnimatedAddGarmentButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AnimatedAddGarmentButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        elevation: 4,
        shadowColor: AppColors.accent.withValues(alpha: 0.45),
      ),
      icon: const Icon(Icons.add_rounded, size: 22),
      label: Text(
        context.l10n.dressingAddGarment,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 850.ms,
          curve: Curves.easeInOut,
        )
        .shimmer(
          delay: 400.ms,
          duration: 1400.ms,
          color: AppColors.white.withValues(alpha: 0.35),
        );
  }
}
