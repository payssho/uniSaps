import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../inspiration/user_profile_screen.dart';
import '../../l10n/l10n_context.dart';

class CreatorProfileScreen extends ConsumerWidget {
  const CreatorProfileScreen({super.key});

  void _copyShopUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.creatorShopLinkCopied)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.authNotConnected));
          }
          final avatar = user.displayAvatarUrl;
          final expires = user.creatorSubscriptionExpiresAt;
          final active = user.isCreatorSubscriptionActive;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.surfaceVariant,
                    backgroundImage:
                        avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                    child: avatar.isEmpty
                        ? const Icon(Icons.storefront, size: 40, color: AppColors.primary)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName.isNotEmpty ? user.displayName : user.username,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading2,
                ),
                if (user.username.isNotEmpty)
                  Text(
                    '@${user.username}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                const SizedBox(height: 20),
                if (user.creatorBio.isNotEmpty)
                  Text(user.creatorBio, style: AppTextStyles.body),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: Icon(
                      active ? Icons.verified_outlined : Icons.warning_amber_outlined,
                      color: active ? AppColors.success : AppColors.warning,
                    ),
                    title: Text(
                      active
                          ? l10n.creatorSubscriptionActive
                          : l10n.creatorSubscriptionInactive,
                    ),
                    subtitle: Text(
                      expires.isNotEmpty
                          ? l10n.creatorSubscriptionExpires(
                              expires.substring(0, 10),
                            )
                          : l10n.creatorSubscriptionRate(
                              l10n.creatorSubscriptionMonthlyPrice,
                            ),
                    ),
                  ),
                ),
                if (user.creatorShopUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.shopping_bag_outlined),
                    title: Text(l10n.creatorShopTitle),
                    subtitle: Text(user.creatorShopUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _copyShopUrl(context, user.creatorShopUrl),
                  ),
                ],
                if (user.linkedUserUid.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(l10n.creatorViewPersonalProfile),
                    trailing: const Icon(Icons.chevron_right),
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
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.authSignOut),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
              child: Text(l10n.commonErrorDetail(e)),
            ),
      ),
    );
  }
}
