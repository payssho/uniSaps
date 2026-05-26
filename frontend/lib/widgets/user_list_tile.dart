import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/user_model.dart';

/// Ligne utilisateur (amis, recherche, listes sociales).
class UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? subtitleOverride;
  final bool bordered;
  final bool dense;
  final bool prefixAtUsername;

  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
    this.trailing,
    this.subtitleOverride,
    this.bordered = true,
    this.dense = false,
    this.prefixAtUsername = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = prefixAtUsername && user.username.isNotEmpty
        ? '@${user.username}'
        : user.username.isNotEmpty
            ? user.username
            : user.displayName;

    final avatarRadius = dense ? 18.0 : 24.0;

    final content = Row(
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: AppColors.surfaceVariant,
          backgroundImage: user.profilePhotoUrl.isNotEmpty
              ? CachedNetworkImageProvider(user.profilePhotoUrl)
              : null,
          child: user.profilePhotoUrl.isEmpty
              ? Text(
                  (user.username.isNotEmpty
                          ? user.username[0]
                          : user.displayName.isNotEmpty
                              ? user.displayName[0]
                              : '?')
                      .toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: dense ? 14 : 18,
                    color: AppColors.textHint,
                  ),
                )
              : null,
        ),
        SizedBox(width: dense ? 12 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: dense ? 14 : 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitleOverride != null)
                Text(
                  subtitleOverride!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else if (user.displayName.isNotEmpty &&
                  user.username.isNotEmpty &&
                  !prefixAtUsername)
                Text(
                  user.displayName,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else if (user.displayName.isNotEmpty &&
                  prefixAtUsername &&
                  user.username.isNotEmpty)
                Text(
                  user.displayName,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );

    if (!bordered) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dense ? 8 : 12),
          child: content,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(dense ? 10 : 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(dense ? 12 : 16),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: content,
      ),
    );
  }
}
