import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUid;
  final VoidCallback onLike;
  final VoidCallback? onTap;
  final VoidCallback? onUserTap;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUid,
    required this.onLike,
    this.onTap,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final liked = post.isLikedBy(currentUid);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onUserTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    CircleAvatar(
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
            if (post.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: post.imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 300,
                  color: AppColors.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: post.garmentRefs.map((ref) {
                        final text = [ref.brand, ref.name].where((s) => s.isNotEmpty).join(' - ');
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        );
                      }).toList(),
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
}
