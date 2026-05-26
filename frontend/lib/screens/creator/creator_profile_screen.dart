import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/creator_subscription.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/creator_post_provider.dart';
import '../../providers/creator_stats_provider.dart';
import '../../providers/garment_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../widgets/post_detail_sheet.dart';
import '../inspiration/user_profile_screen.dart';

class CreatorProfileScreen extends ConsumerWidget {
  const CreatorProfileScreen({super.key});

  void _copyShopUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien boutique copié')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Non connecté'));
          }
          final posts =
              ref.watch(creatorPostsProvider(user.uid)).valueOrNull ?? [];
          final stats = ref.watch(creatorStatsProvider);
          final garments =
              ref.watch(garmentsProvider(user.uid)).valueOrNull ?? [];
          final outfits = ref.watch(outfitsProvider(user.uid)).valueOrNull ?? [];
          final topPosts = stats.topPostsByViews(posts);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _CreatorProfileHero(user: user, stats: stats, garmentCount: garments.length),
                if (topPosts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Performance', style: AppTextStyles.heading3),
                  const SizedBox(height: 10),
                  ...topPosts.map(
                    (p) => _TopPostRow(
                      post: p,
                      onTap: () => PostDetailSheet.show(
                        context,
                        p,
                        ownerGarments: garments,
                        ownerOutfits: outfits,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Espace marque', style: AppTextStyles.heading3),
                const SizedBox(height: 10),
                _CreatorSubscriptionTile(user: user),
                if (user.creatorShopUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _CreatorActionTile(
                    icon: Icons.shopping_bag_outlined,
                    iconColor: AppColors.accent,
                    title: 'Boutique',
                    subtitle: user.creatorShopUrl,
                    onTap: () => _copyShopUrl(context, user.creatorShopUrl),
                  ),
                ],
                if (user.linkedUserUid.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _CreatorActionTile(
                    icon: Icons.person_outline,
                    title: 'Profil perso',
                    subtitle: 'Voir ton compte utilisateur',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              UserProfileScreen(userId: user.linkedUserUid),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Déconnexion'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}

class _CreatorProfileHero extends StatelessWidget {
  final UserModel user;
  final CreatorStats stats;
  final int garmentCount;

  const _CreatorProfileHero({
    required this.user,
    required this.stats,
    required this.garmentCount,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = user.displayAvatarUrl;
    final active = user.isCreatorSubscriptionActive;
    final expires = user.creatorSubscriptionExpiresAt;
    final displayName =
        user.displayName.isNotEmpty ? user.displayName : user.username;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cardGradientStart,
                    AppColors.surface,
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.accent.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage:
                      avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                  child: avatar.isEmpty
                      ? const Icon(Icons.storefront,
                          size: 40, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(displayName, style: AppTextStyles.heading2),
                if (user.username.isNotEmpty)
                  Text('@${user.username}', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active
                            ? Icons.verified_outlined
                            : Icons.warning_amber_outlined,
                        size: 16,
                        color: active ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        active ? 'Créateur actif' : 'Abonnement inactif',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              active ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                if (expires.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Expire le ${expires.substring(0, 10)}',
                      style: AppTextStyles.caption,
                    ),
                  ),
                if (user.creatorBio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    user.creatorBio,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body,
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.75),
                    ),
                  ),
                  child: Row(
                    children: [
                      _StatCell(
                        label: 'Posts',
                        value: '${stats.totalPosts}',
                        icon: Icons.campaign_outlined,
                        color: AppColors.primary,
                      ),
                      _statDivider(),
                      _StatCell(
                        label: 'Actifs',
                        value: '${stats.activePosts}',
                        icon: Icons.visibility_outlined,
                        color: AppColors.accent,
                      ),
                      _statDivider(),
                      _StatCell(
                        label: 'Vues',
                        value: _fmtCount(stats.totalViews),
                        icon: Icons.remove_red_eye_outlined,
                        color: AppColors.secondary,
                      ),
                      _statDivider(),
                      _StatCell(
                        label: 'Likes',
                        value: _fmtCount(stats.totalLikes),
                        icon: Icons.favorite_border,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.checkroom_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '$garmentCount pièces au dressing',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

Widget _statDivider() {
  return Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: AppColors.divider.withValues(alpha: 0.85),
  );
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPostRow extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const _TopPostRow({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = post.displayImageUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 64,
                    child: url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(color: AppColors.surfaceVariant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.caption.isNotEmpty
                            ? post.caption
                            : 'Post sponsorisé',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${post.viewCount} vues · ${post.likes} likes',
                        style: AppTextStyles.caption,
                      ),
                      if (!post.isActive)
                        Text(
                          'Inactif dans le feed',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreatorSubscriptionTile extends StatelessWidget {
  final UserModel user;

  const _CreatorSubscriptionTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final active = user.isCreatorSubscriptionActive;
    return _CreatorActionTile(
      icon: active ? Icons.verified_outlined : Icons.warning_amber_outlined,
      iconColor: active ? AppColors.success : AppColors.warning,
      title: active ? 'Abonnement actif' : 'Renouveler l’abonnement',
      subtitle: active
          ? (user.creatorSubscriptionExpiresAt.isNotEmpty
              ? 'Expire le ${user.creatorSubscriptionExpiresAt.substring(0, 10)}'
              : kCreatorMonthlyPriceLabel)
          : 'Tarif : $kCreatorMonthlyPriceLabel',
      onTap: active
          ? null
          : () => context.push('/creator/checkout'),
    );
  }
}

class _CreatorActionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _CreatorActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.75)),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
