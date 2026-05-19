import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/creator_subscription.dart';
import '../../providers/auth_provider.dart';
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
                    title: Text(active ? 'Abonnement actif' : 'Abonnement inactif'),
                    subtitle: Text(
                      expires.isNotEmpty
                          ? 'Expire le ${expires.substring(0, 10)}'
                          : 'Tarif : $kCreatorMonthlyPriceLabel',
                    ),
                  ),
                ),
                if (user.creatorShopUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.shopping_bag_outlined),
                    title: const Text('Boutique'),
                    subtitle: Text(user.creatorShopUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _copyShopUrl(context, user.creatorShopUrl),
                  ),
                ],
                if (user.linkedUserUid.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Voir mon profil perso'),
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
                  label: const Text('Déconnexion'),
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
