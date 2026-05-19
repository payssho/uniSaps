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

class CreatorDressingScreen extends ConsumerWidget {
  const CreatorDressingScreen({super.key});

  void _showAddGarment(BuildContext context, {String? collectionId}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGarmentSheet(
        requireCollection: true,
        initialCollectionId: collectionId,
        creatorCatalogMode: true,
      ),
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
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            builder: (_) => AddGarmentSheet(
              garment: garment,
              requireCollection: true,
              initialCollectionId: garment.collectionId,
              creatorCatalogMode: true,
            ),
          );
        },
        onDelete: () async {
          Navigator.pop(sheetCtx);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Supprimer ce vêtement ?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
              ],
            ),
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

          return AlertDialog(
            title: const Text('Nouvelle collection'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Nom de la collection',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date de début'),
                    subtitle: Text(_isoDate(startDate)),
                    trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                    onTap: pickStart,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date de fin'),
                    subtitle: Text(_isoDate(endDate)),
                    trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                    onTap: pickEnd,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Créer')),
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
        const SnackBar(content: Text('Indique un nom de collection.')),
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
    CollectionModel collection,
    int garmentCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la collection ?'),
        content: Text(
          garmentCount > 0
              ? '« ${collection.name} » et ses $garmentCount pièce${garmentCount > 1 ? 's' : ''} '
                  'seront supprimées définitivement.'
              : '« ${collection.name} » sera supprimée.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final success = await ref.read(collectionNotifierProvider.notifier).deleteCollection(
          uid: uid,
          collectionId: collection.id,
        );
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection supprimée.')),
      );
    } else {
      final err = ref.read(collectionNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err != null ? '$err' : 'Suppression impossible.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  const Expanded(
                    child: Text('Catalogue marque', style: AppTextStyles.heading2),
                  ),
                  IconButton(
                    tooltip: 'Nouvelle collection',
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
                            const Text(
                              'Crée une collection pour organiser ton catalogue.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySecondary,
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => _createCollection(context, ref, uid),
                              icon: const Icon(Icons.add),
                              label: const Text('Nouvelle collection'),
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
                        onAdd: () => _showAddGarment(context, collectionId: col.id),
                        onGarmentTap: (g) => _showGarmentDetails(context, ref, uid, g),
                        onDeleteCollection: () =>
                            _confirmDeleteCollection(context, ref, col, items.length),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, _) => Center(child: Text('Erreur : $e')),
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
          label: const Text(
            'Ajouter',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _CollectionSection extends StatelessWidget {
  final CollectionModel collection;
  final List<GarmentModel> garments;
  final VoidCallback onAdd;
  final VoidCallback onDeleteCollection;
  final void Function(GarmentModel) onGarmentTap;

  const _CollectionSection({
    required this.collection,
    required this.garments,
    required this.onAdd,
    required this.onDeleteCollection,
    required this.onGarmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(collection.name, style: AppTextStyles.heading3),
                    if (collection.startDate.isNotEmpty)
                      Text(
                        '${collection.startDate} → ${collection.endDate}',
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Supprimer la collection',
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.error,
                onPressed: onDeleteCollection,
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Pièce'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (garments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Aucun vêtement dans cette collection.',
                  style: AppTextStyles.bodySecondary),
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
