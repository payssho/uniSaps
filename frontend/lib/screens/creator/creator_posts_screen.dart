import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/collection_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/creator_post_provider.dart';
import '../../providers/garment_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/post_card.dart';
import '../../widgets/post_detail_sheet.dart';
import 'creator_post_create_screen.dart';

class CreatorPostsScreen extends ConsumerStatefulWidget {
  const CreatorPostsScreen({super.key});

  @override
  ConsumerState<CreatorPostsScreen> createState() => _CreatorPostsScreenState();
}

class _CreatorPostsScreenState extends ConsumerState<CreatorPostsScreen> {
  String? _filterCollectionId;

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CreatorPostCreateScreen(),
      ),
    );
  }

  Map<String, List<PostModel>> _groupByCollection(
    List<PostModel> posts,
    List<CollectionModel> collections,
  ) {
    final grouped = <String, List<PostModel>>{};
    for (final p in posts) {
      final key = p.collectionId.isNotEmpty ? p.collectionId : '_none';
      grouped.putIfAbsent(key, () => []).add(p);
    }
    if (_filterCollectionId != null) {
      return {
        _filterCollectionId!: grouped[_filterCollectionId] ?? [],
      };
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).uid;
    final postsAsync = ref.watch(creatorPostsProvider(uid));
    final collectionsAsync = ref.watch(collectionsProvider(uid));
    final garments = ref.watch(garmentsProvider(uid)).valueOrNull ?? [];
    final outfits = ref.watch(outfitsProvider(uid)).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Post pub'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Posts publicitaires', style: AppTextStyles.heading2),
            ),
            collectionsAsync.when(
              data: (cols) {
                if (cols.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      FilterChip(
                        label: const Text('Toutes'),
                        selected: _filterCollectionId == null,
                        onSelected: (_) => setState(() => _filterCollectionId = null),
                      ),
                      const SizedBox(width: 8),
                      ...cols.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(c.name),
                            selected: _filterCollectionId == c.id,
                            onSelected: (_) =>
                                setState(() => _filterCollectionId = c.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Expanded(
              child: postsAsync.when(
                data: (posts) {
                  return collectionsAsync.when(
                    data: (collections) {
                      final grouped = _groupByCollection(posts, collections);
                      if (grouped.values.every((l) => l.isEmpty)) {
                        return const AppEmptyState(
                          icon: Icons.campaign_outlined,
                          title: 'Aucun post pour l’instant.',
                          size: AppEmptyStateSize.compact,
                        );
                      }
                      final colNames = {
                        for (final c in collections) c.id: c.name,
                        '_none': 'Sans collection',
                      };
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        children: grouped.entries.map((e) {
                          final title = colNames[e.key] ?? e.key;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 8),
                                child: Text(title, style: AppTextStyles.heading3),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.51,
                                ),
                                itemCount: e.value.length,
                                itemBuilder: (_, i) {
                                  final post = e.value[i];
                                  final uid =
                                      ref.read(authServiceProvider).uid;
                                  return PostCard(
                                    post: post,
                                    currentUid: uid,
                                    layout: PostCardLayout.grid,
                                    creatorGrid: true,
                                    ownerGarments: garments,
                                    ownerOutfits: outfits,
                                    onLike: () {},
                                    onTap: () => PostDetailSheet.show(
                                      context,
                                      post,
                                      ownerGarments: garments,
                                      ownerOutfits: outfits,
                                    ),
                                    onActiveChanged: (v) => ref
                                        .read(creatorPostNotifierProvider
                                            .notifier)
                                        .setPostActive(post.id, v),
                                  );
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
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
