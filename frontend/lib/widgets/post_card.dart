import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'storage_aware_cached_image.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radii.dart';
import '../core/constants/app_text_styles.dart';
import '../models/garment_model.dart';
import '../models/outfit_model.dart';
import '../models/post_model.dart';
import 'premium_avatar_ring.dart';
import 'post_garment_refs.dart';

/// Présentation de la carte : pleine largeur ou tuile de grille (2 colonnes).
enum PostCardLayout {
  /// Carte pleine largeur (aperçu créateur, détail).
  standard,
  /// Tuile grille : image plus haute, texte compact.
  grid,
}

class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUid;
  final VoidCallback onLike;
  final VoidCallback? onTap;
  final VoidCallback? onUserTap;
  final PostCardLayout layout;
  final List<GarmentModel>? ownerGarments;
  final List<OutfitModel>? ownerOutfits;
  /// Grille admin créateur : pas de header social, footer actif/inactif.
  final bool creatorGrid;
  final ValueChanged<bool>? onActiveChanged;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUid,
    required this.onLike,
    this.onTap,
    this.onUserTap,
    this.layout = PostCardLayout.standard,
    this.ownerGarments,
    this.ownerOutfits,
    this.creatorGrid = false,
    this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return layout == PostCardLayout.grid
        ? _buildGridCard(context)
        : _buildStandardCard(context);
  }

  Widget _buildStandardCard(BuildContext context) {
    final liked = post.isLikedBy(currentUid);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [
            BoxShadow(
              color: AppColors.graphite.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.isSponsored)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Icon(Icons.campaign_outlined,
                        size: 14, color: AppColors.primary.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text(
                      'Sponsorisé',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary.withValues(alpha: 0.95),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            GestureDetector(
              onTap: onUserTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    PremiumAvatarRing(
                      isPremium: post.authorIsPremium,
                      padding: 2.5,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surfaceVariant,
                        backgroundImage: post.userPhotoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(post.userPhotoUrl)
                            : null,
                        child: post.userPhotoUrl.isEmpty
                            ? Text(
                                post.username.isNotEmpty ? post.username[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textHint),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.username,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          if (post.createdAt.isNotEmpty)
                            Text(
                              post.createdAt.substring(0, 10),
                              style: AppTextStyles.caption,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    if (post.displayImageUrl.isEmpty) {
                      return Container(
                        width: w,
                        height: h,
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: Icon(
                            Icons.photo_library_outlined,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                        ),
                      );
                    }
                    return StorageAwareCachedImage(
                      imageUrl: post.displayImageUrl,
                      width: w,
                      height: h,
                      fit: BoxFit.cover,
                      preferHighQuality: true,
                      loadingWidget: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textHint,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onLike,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(liked),
                            color: liked ? AppColors.accent : AppColors.textHint,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likes}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  if (post.caption.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(post.caption, style: AppTextStyles.body),
                  ],
                  if (post.garmentRefs.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Pièces du look',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PostGarmentRefsForPost(
                      post: post,
                      ownerGarments: ownerGarments,
                      ownerOutfits: ownerOutfits,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    if (creatorGrid) {
      return _buildCreatorGridCard(context);
    }
    final liked = post.isLikedBy(currentUid);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.graphite.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onUserTap,
                    behavior: HitTestBehavior.opaque,
                    child: PremiumAvatarRing(
                      isPremium: post.authorIsPremium,
                      padding: 2,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.surfaceVariant,
                        backgroundImage: post.userPhotoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(post.userPhotoUrl)
                            : null,
                        child: post.userPhotoUrl.isEmpty
                            ? Text(
                                post.username.isNotEmpty ? post.username[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textHint,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: onUserTap,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          if (post.createdAt.isNotEmpty)
                            Text(
                              post.createdAt.substring(0, 10),
                              style: AppTextStyles.caption.copyWith(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        post.displayImageUrl.isNotEmpty
                            ? StorageAwareCachedImage(
                                imageUrl: post.displayImageUrl,
                                fit: BoxFit.cover,
                                width: w,
                                height: h,
                                preferHighQuality: true,
                              loadingWidget: Container(
                                color: AppColors.surfaceVariant,
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textHint,
                                  size: 32,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.surfaceVariant,
                              child: const Center(
                                child: Icon(
                                  Icons.photo_library_outlined,
                                  size: 36,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                  if (post.isSponsored)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Sponsorisé',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onLike,
                          child: Icon(
                            liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: liked ? AppColors.accent : AppColors.textHint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likes}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                    if (post.caption.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        post.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.25),
                      ),
                    ],
                    if (post.garmentRefs.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      PostGarmentRefsForPost(
                        post: post,
                        maxVisible: 3,
                        compact: true,
                        onViewAll: onTap,
                        ownerGarments: ownerGarments,
                        ownerOutfits: ownerOutfits,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorGridCard(BuildContext context) {
    final imageUrl = post.displayImageUrl;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.65),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  if (imageUrl.isEmpty) {
                    return Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.textHint,
                      ),
                    );
                  }
                  return StorageAwareCachedImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: w,
                    height: h,
                    loadingWidget: Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, __) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.textHint,
                      ),
                    ),
                  );
                },
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (post.viewCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${post.viewCount} vues',
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: post.isActive
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.textHint.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: post.isActive
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (onActiveChanged != null)
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
                              onChanged: onActiveChanged,
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
