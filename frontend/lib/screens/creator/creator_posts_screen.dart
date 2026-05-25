import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/collection_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/creator_post_provider.dart';
import '../../widgets/creator_post_preview_sheet.dart';
import 'creator_post_create_sheet.dart';
import '../../l10n/l10n_context.dart';

class CreatorPostsScreen extends ConsumerStatefulWidget {
  const CreatorPostsScreen({super.key});

  @override
  ConsumerState<CreatorPostsScreen> createState() => _CreatorPostsScreenState();
}

class _CreatorPostsScreenState extends ConsumerState<CreatorPostsScreen> {
  String? _filterCollectionId;

  void _openCreate() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatorPostCreateSheet(),
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
    final l10n = context.l10n;
    final uid = ref.watch(authServiceProvider).uid;
    final postsAsync = ref.watch(creatorPostsProvider(uid));
    final collectionsAsync = ref.watch(collectionsProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: Text(l10n.creatorPostPubLabel),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(l10n.creatorPostsTitle, style: AppTextStyles.heading2),
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
                        label: Text(l10n.commonAll),
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
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.campaign_outlined,
                                  size: 48,
                                  color: AppColors.textHint.withValues(alpha: 0.6)),
                              const SizedBox(height: 12),
                              Text(l10n.creatorPostsEmpty,
                                  style: AppTextStyles.bodySecondary),
                            ],
                          ),
                        );
                      }
                      final colNames = {
                        for (final c in collections) c.id: c.name,
                        '_none': l10n.creatorPostsNoCollection,
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
                                itemBuilder: (_, i) =>
                                    _PostTile(post: e.value[i]),
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
                error: (e, _) => Center(
                      child: Text(l10n.commonErrorDetail(e)),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostTile extends ConsumerWidget {
  final PostModel post;

  const _PostTile({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = post.displayImageUrl;
    final radius = BorderRadius.circular(14);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.65)),
      ),
      child: InkWell(
        onTap: () => CreatorPostPreviewSheet.show(context, post),
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      placeholder: (_, __) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceVariant,
                      child:
                          const Icon(Icons.image_outlined, color: AppColors.textHint),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.caption.isNotEmpty ? post.caption : 'Post sponsorisé',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: post.isActive
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.textHint.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              post.isActive ? 'Actif' : 'Inactif',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: post.isActive
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        width: 42,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.centerRight,
                          child: Switch.adaptive(
                            value: post.isActive,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) => ref
                                .read(creatorPostNotifierProvider.notifier)
                                .setPostActive(post.id, v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
