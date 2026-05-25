import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/collection_model.dart';
import '../../models/garment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/garment_provider.dart';
import '../../widgets/add_garment_sheet.dart';
import '../../widgets/garment_card.dart';
import '../../widgets/garment_detail_sheet.dart';
import '../../l10n/l10n_context.dart';

class CreatorDressingScreen extends ConsumerWidget {
  const CreatorDressingScreen({super.key});

  void _showAddGarment(BuildContext context, {String? collectionId}) {
    pushAddGarmentRoute(
      context,
      requireCollection: true,
      initialCollectionId: collectionId,
      creatorCatalogMode: true,
    );
  }

  void _showGarmentDetails(
    BuildContext context,
    WidgetRef ref,
    String uid,
    GarmentModel garment,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => GarmentDetailSheet(
        garment: garment,
        onEdit: () {
          Navigator.pop(sheetCtx);
          pushAddGarmentRoute(
            context,
            garment: garment,
            requireCollection: true,
            initialCollectionId: garment.collectionId,
            creatorCatalogMode: true,
          );
        },
        onDelete: () async {
          Navigator.pop(sheetCtx);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) {
              final l10n = ctx.l10n;
              return AlertDialog(
                title: Text(l10n.garmentDeleteConfirmTitle),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.commonCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.commonDelete),
                  ),
                ],
              );
            },
          );
          if (confirmed == true) {
            await ref.read(garmentNotifierProvider.notifier).deleteGarment(uid, garment.id);
          }
        },
      ),
    );
  }

  static String _isoDate(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> _createCollection(BuildContext context, WidgetRef ref, String uid) async {
    final l10n = context.l10n;
    final nameController = TextEditingController();
    var startDate = DateTime.now();
    var endDate = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Future<void> pickStart() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: startDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) setLocal(() => startDate = picked);
          }

          Future<void> pickEnd() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: endDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) setLocal(() => endDate = picked);
          }

          final dlgL10n = ctx.l10n;
          return AlertDialog(
            title: Text(dlgL10n.garmentCollectionNew),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: dlgL10n.garmentCollectionNameHint,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(dlgL10n.garmentCollectionStartDate),
                    subtitle: Text(_isoDate(startDate)),
                    trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                    onTap: pickStart,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(dlgL10n.garmentCollectionEndDate),
                    subtitle: Text(_isoDate(endDate)),
                    trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                    onTap: pickEnd,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(dlgL10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(dlgL10n.commonCreate),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || !context.mounted) {
      nameController.dispose();
      return;
    }
    final name = nameController.text.trim();
    nameController.dispose();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.garmentCollectionNameRequiredSnack)),
      );
      return;
    }

    var s = startDate;
    var e = endDate;
    if (e.isBefore(s)) {
      final tmp = s;
      s = e;
      e = tmp;
    }

    await ref.read(collectionNotifierProvider.notifier).createCollection(
          userId: uid,
          name: name,
          startDate: _isoDate(s),
          endDate: _isoDate(e),
        );
  }

  Future<void> _confirmDeleteCollection(
    BuildContext context,
    WidgetRef ref,
    String uid,
    CollectionModel collection,
    int garmentCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dlgL10n = ctx.l10n;
        final String body;
        if (garmentCount > 1) {
          body = dlgL10n.garmentCollectionDeleteWithPieces(
            garmentCount,
            collection.name,
          );
        } else if (garmentCount == 1) {
          body = dlgL10n.garmentCollectionDeleteWithPiece(collection.name);
        } else {
          body = dlgL10n.garmentCollectionDeleteOnly(collection.name);
        }
        return AlertDialog(
          title: Text(dlgL10n.garmentDeleteCollectionTitle),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dlgL10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dlgL10n.commonDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final success = await ref.read(collectionNotifierProvider.notifier).deleteCollection(
          uid: uid,
          collectionId: collection.id,
        );
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.garmentCollectionDeleted)),
      );
    } else {
      final err = ref.read(collectionNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err != null ? '$err' : context.l10n.garmentCollectionDeleteFailed,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final uid = ref.watch(authServiceProvider).uid;
    final collectionsAsync = ref.watch(collectionsProvider(uid));
    final grouped = ref.watch(garmentsByCollectionProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.creatorCatalogTitle, style: AppTextStyles.heading2),
                  ),
                  IconButton(
                    tooltip: l10n.creatorNewCollectionTooltip,
                    onPressed: () => _createCollection(context, ref, uid),
                    icon: const Icon(Icons.create_new_folder_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: collectionsAsync.when(
                data: (collections) {
                  final sorted = List<CollectionModel>.from(collections)
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  if (sorted.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.collections_outlined,
                                size: 48, color: AppColors.textHint.withValues(alpha: 0.6)),
                            const SizedBox(height: 16),
                            Text(
                              l10n.creatorCatalogEmptyHint,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySecondary,
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => _createCollection(context, ref, uid),
                              icon: const Icon(Icons.add),
                              label: Text(l10n.garmentCollectionNew),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final col = sorted[index];
                      final items = grouped[col.id] ?? <GarmentModel>[];
                      return _CollectionSection(
                        collection: col,
                        garments: items,
                        onDeleteCollection: () =>
                            _confirmDeleteCollection(context, ref, uid, col, items.length),
                        onGarmentTap: (g) => _showGarmentDetails(context, ref, uid, g),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, _) => Center(
                      child: Text(l10n.commonErrorDetail(e)),
                    ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton.extended(
          heroTag: 'creator_catalog_fab',
          backgroundColor: AppColors.accent,
          elevation: 6,
          onPressed: () => _showAddGarment(context),
          icon: const Icon(Icons.add, color: AppColors.white, size: 24),
          label: Text(
            l10n.commonAdd,
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _CollectionSection extends StatelessWidget {
  final CollectionModel collection;
  final List<GarmentModel> garments;
  final VoidCallback onDeleteCollection;
  final void Function(GarmentModel) onGarmentTap;

  const _CollectionSection({
    required this.collection,
    required this.garments,
    required this.onDeleteCollection,
    required this.onGarmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = garments.length;
    final dateLine = collection.startDate.isNotEmpty
        ? '${collection.startDate} → ${collection.endDate}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface,
                  AppColors.accent.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.graphite.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.accent,
                          AppColors.primary.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            collection.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (dateLine.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.accent.withValues(alpha: 0.22),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        size: 13,
                                        color: AppColors.accent.withValues(alpha: 0.95),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        dateLine,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary.withValues(alpha: 0.95),
                                          letterSpacing: 0.05,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.checkroom_rounded,
                                      size: 13,
                                      color: AppColors.primary.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      count == 0
                                          ? context.l10n.creatorCollectionNoPieces
                                          : count == 1
                                              ? context.l10n.creatorCollectionOnePiece
                                              : context.l10n
                                                  .creatorCollectionPieceCount(count),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary.withValues(alpha: 0.95),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
                    child: IconButton(
                      tooltip: context.l10n.garmentDeleteCollectionTitle,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.error,
                        backgroundColor: AppColors.graphite.withValues(alpha: 0.08),
                      ),
                      onPressed: onDeleteCollection,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (garments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.65),
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 36,
                    color: AppColors.textHint.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.creatorCollectionEmptyTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.creatorCollectionEmptyHint,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: AppColors.textHint.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: garments.length,
              itemBuilder: (context, i) {
                final g = garments[i];
                return GarmentCard(
                  garment: g,
                  onTap: () => onGarmentTap(g),
                );
              },
            ),
        ],
      ),
    );
  }
}
