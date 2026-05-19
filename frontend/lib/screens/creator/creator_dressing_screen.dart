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

  Future<void> _createCollection(BuildContext context, WidgetRef ref, String uid) async {
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle collection'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nom de la collection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Créer')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await ref.read(collectionNotifierProvider.notifier).createCollection(
          userId: uid,
          name: name,
          startDate: today,
          endDate: today,
        );
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
                  IconButton(
                    tooltip: 'Ajouter un vêtement',
                    onPressed: () => _showAddGarment(context),
                    icon: const Icon(Icons.add),
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final col = sorted[index];
                      final items = grouped[col.id] ?? <GarmentModel>[];
                      return _CollectionSection(
                        collection: col,
                        garments: items,
                        onAdd: () => _showAddGarment(context, collectionId: col.id),
                        onGarmentTap: (g) => _showGarmentDetails(context, ref, uid, g),
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
    );
  }
}

class _CollectionSection extends StatelessWidget {
  final CollectionModel collection;
  final List<GarmentModel> garments;
  final VoidCallback onAdd;
  final void Function(GarmentModel) onGarmentTap;

  const _CollectionSection({
    required this.collection,
    required this.garments,
    required this.onAdd,
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
