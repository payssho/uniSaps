import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radii.dart';
import '../core/constants/app_text_styles.dart';
import '../models/post_model.dart';
import '../screens/inspiration/user_profile_screen.dart';
import 'post_garment_refs.dart';
import 'premium_avatar_ring.dart';
import 'storage_aware_cached_image.dart';

/// Sheet détail d'un post : auteur, photo, légende, pièces du look.
class PostDetailSheet extends ConsumerStatefulWidget {
  final PostModel post;

  const PostDetailSheet({super.key, required this.post});

  static Future<void> show(BuildContext context, PostModel post) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostDetailSheet(post: post),
    );
  }

  @override
  ConsumerState<PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends ConsumerState<PostDetailSheet> {
  final _scrollController = ScrollController();
  final _garmentsSectionKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToGarments() async {
    final ctx = _garmentsSectionKey.currentContext;
    if (ctx == null || !mounted) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;
    final imageUrl = post.displayImageUrl;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadii.sheet),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Détail du look',
                              style: AppTextStyles.heading3,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _AuthorRow(post: post),
                      if (imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadii.card + 2),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                StorageAwareCachedImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  loadingWidget: Container(
                                    color: AppColors.surfaceVariant,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __) => Container(
                                    color: AppColors.surfaceVariant,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.textHint,
                                      size: 40,
                                    ),
                                  ),
                                ),
                                if (post.garmentRefs.isNotEmpty)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            AppColors.graphite
                                                .withValues(alpha: 0.35),
                                          ],
                                        ),
                                      ),
                                      child: PostGarmentScrollHint(
                                        itemCount: post.garmentRefs.length,
                                        onTap: _scrollToGarments,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (post.caption.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          post.caption,
                          style: AppTextStyles.body.copyWith(height: 1.4),
                        ),
                      ],
                      if (post.garmentRefs.isNotEmpty) ...[
                        KeyedSubtree(
                          key: _garmentsSectionKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.checkroom_rounded,
                                      size: 20,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Pièces du look',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${post.garmentRefs.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              PostGarmentRefsDetailForPost(post: post),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  final PostModel post;

  const _AuthorRow({required this.post});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: post.userId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              PremiumAvatarRing(
                isPremium: post.authorIsPremium,
                padding: 2.5,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: post.userPhotoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(post.userPhotoUrl)
                      : null,
                  child: post.userPhotoUrl.isEmpty
                      ? Text(
                          post.username.isNotEmpty
                              ? post.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (post.createdAt.isNotEmpty)
                      Text(
                        post.createdAt.substring(0, 10),
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
              if (post.isSponsored)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Sponsorisé',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
