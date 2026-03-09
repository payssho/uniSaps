import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/garment_model.dart';
import '../../models/outfit_model.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/friendship_provider.dart';
import 'search_users_screen.dart';
import 'user_profile_screen.dart';

class InspirationScreen extends ConsumerStatefulWidget {
  const InspirationScreen({super.key});

  @override
  ConsumerState<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends ConsumerState<InspirationScreen> {
  bool _showFriends = true;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).uid;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final requestCount = ref.watch(receivedRequestsCountProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Full-screen feed
          _showFriends
              ? _FriendsFeed(uid: uid, user: user)
              : _ExploreFeed(uid: uid, user: user),

          // Top overlay: tab toggle + actions
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 60,
            child: Row(
              children: [
                _FeedToggle(
                  showFriends: _showFriends,
                  onToggle: (v) => setState(() => _showFriends = v),
                ),
                const Spacer(),
                _TopActionButton(
                  icon: Icons.person_add_outlined,
                  badge: requestCount,
                  onTap: () => _showFriendRequests(context),
                ),
                const SizedBox(width: 4),
                _TopActionButton(
                  icon: Icons.search,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SearchUsersScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Publish FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: _PublishButton(onTap: () => _showPublishSheet(context)),
          ),
        ],
      ),
    );
  }

  void _showFriendRequests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FriendRequestsSheet(),
    );
  }

  Future<void> _showPublishSheet(BuildContext context) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    if (user.dailyOutfitId.isEmpty || user.dailyPhotoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Pour publier, choisis d\'abord un outfit du jour et prends la photo.',
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final uid = ref.read(authServiceProvider).uid;
    try {
      final outfit = await ref
          .read(firestoreServiceProvider)
          .getOutfit(uid, user.dailyOutfitId);
      if (outfit == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible de récupérer l\'outfit du jour.')),
        );
        return;
      }

      final garments = <GarmentModel>[];
      for (final gid in outfit.garmentIds) {
        final g =
            await ref.read(firestoreServiceProvider).getGarment(uid, gid);
        if (g != null) garments.add(g);
      }

      if (!mounted) return;
      _showDailyPostSheet(context, user, outfit, garments);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors de la préparation du post.')),
      );
    }
  }

  void _showDailyPostSheet(
    BuildContext context,
    dynamic user,
    OutfitModel outfit,
    List<GarmentModel> garments,
  ) {
    final captionController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Publier l\'outfit du jour',
                      style: AppTextStyles.heading3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: CachedNetworkImage(
                    imageUrl: user.dailyPhotoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                outfit.name.isNotEmpty ? outfit.name : 'Mon outfit du jour',
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (garments.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: garments.map((g) {
                    final text = [g.brand, g.name]
                        .where((s) => s.isNotEmpty)
                        .join(' - ');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(text,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: captionController,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Légende (optionnel)...',
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(postNotifierProvider.notifier)
                        .createPostFromDaily(
                          user: user,
                          outfit: outfit,
                          garments: garments,
                          caption: captionController.text.trim(),
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Publier',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Feed toggle (Amis / Explorer)
// ---------------------------------------------------------------------------
class _FeedToggle extends StatelessWidget {
  final bool showFriends;
  final ValueChanged<bool> onToggle;

  const _FeedToggle({required this.showFriends, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'Amis',
            active: showFriends,
            onTap: () => onToggle(true),
          ),
          _ToggleChip(
            label: 'Explorer',
            active: !showFriends,
            onTap: () => onToggle(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top action buttons
// ---------------------------------------------------------------------------
class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.icon,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (badge > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Publish button
// ---------------------------------------------------------------------------
class _PublishButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PublishButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.accentLight],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Publier',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Friends feed (TikTok style)
// ---------------------------------------------------------------------------
class _FriendsFeed extends ConsumerWidget {
  final String uid;
  final UserModel? user;

  const _FriendsFeed({required this.uid, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(friendsPostsProvider);

    return postsAsync.when(
      data: (posts) {
        if (user != null && user!.friends.isEmpty) {
          return _EmptyFeedMessage(
            icon: Icons.people_outline,
            title: 'Aucun ami pour le moment',
            subtitle: 'Recherche des utilisateurs pour les ajouter !',
            action: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SearchUsersScreen()),
                );
              },
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Trouver des amis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        }

        if (posts.isEmpty) {
          return const _EmptyFeedMessage(
            icon: Icons.article_outlined,
            title: 'Aucun post de tes amis',
            subtitle: 'Tes amis n\'ont pas encore publié.',
          );
        }

        return _FullScreenFeed(posts: posts, uid: uid);
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: const TextStyle(color: Colors.white))),
    );
  }
}

// ---------------------------------------------------------------------------
// Explore feed (TikTok style)
// ---------------------------------------------------------------------------
class _ExploreFeed extends ConsumerWidget {
  final String uid;
  final UserModel? user;

  const _ExploreFeed({required this.uid, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const _EmptyFeedMessage(
            icon: Icons.explore_outlined,
            title: 'Aucun post',
            subtitle: 'Sois le premier à partager !',
          );
        }
        return _FullScreenFeed(posts: posts, uid: uid);
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: const TextStyle(color: Colors.white))),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen vertical PageView feed
// ---------------------------------------------------------------------------
class _FullScreenFeed extends ConsumerWidget {
  final List<PostModel> posts;
  final String uid;

  const _FullScreenFeed({required this.posts, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _FullScreenPost(
          post: posts[index],
          uid: uid,
          onLike: () {
            ref
                .read(postNotifierProvider.notifier)
                .toggleLike(posts[index].id, uid);
          },
          onUserTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    UserProfileScreen(userId: posts[index].userId),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Single full-screen post (TikTok style)
// ---------------------------------------------------------------------------
class _FullScreenPost extends StatelessWidget {
  final PostModel post;
  final String uid;
  final VoidCallback onLike;
  final VoidCallback onUserTap;

  const _FullScreenPost({
    required this.post,
    required this.uid,
    required this.onLike,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final liked = post.isLikedBy(uid);
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        if (post.imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: post.imageUrl,
            fit: BoxFit.cover,
            width: screenSize.width,
            height: screenSize.height,
            placeholder: (_, __) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey[900],
              child: const Icon(Icons.broken_image_outlined,
                  color: Colors.white38, size: 48),
            ),
          )
        else
          Container(color: Colors.grey[900]),

        // Top gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 160,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 320,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // Right side actions
        Positioned(
          right: 14,
          bottom: 140,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User avatar
              GestureDetector(
                onTap: onUserTap,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.accent, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: post.userPhotoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(
                                post.userPhotoUrl)
                            : null,
                        child: post.userPhotoUrl.isEmpty
                            ? Text(
                                post.username.isNotEmpty
                                    ? post.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Like button
              GestureDetector(
                onTap: onLike,
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(liked),
                        color: liked ? AppColors.accent : Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${post.likes}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Garment details button
              if (post.garmentRefs.isNotEmpty)
                GestureDetector(
                  onTap: () => _showPostDetails(context, post),
                  child: const Column(
                    children: [
                      Icon(Icons.checkroom, color: Colors.white, size: 28),
                      SizedBox(height: 4),
                      Text(
                        'Détails',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Bottom info (username, caption, garment refs)
        Positioned(
          bottom: 40,
          left: 16,
          right: 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onUserTap,
                child: Text(
                  '@${post.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (post.caption.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  post.caption,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (post.garmentRefs.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: post.garmentRefs.take(3).map((ref) {
                    final text = [ref.brand, ref.name]
                        .where((s) => s.isNotEmpty)
                        .join(' - ');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showPostDetails(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostDetailSheet(post: post),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty feed message
// ---------------------------------------------------------------------------
class _EmptyFeedMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _EmptyFeedMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Post detail sheet
// ---------------------------------------------------------------------------
class _PostDetailSheet extends StatelessWidget {
  final PostModel post;

  const _PostDetailSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProfileScreen(userId: post.userId),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.surfaceVariant,
                          backgroundImage: post.userPhotoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  post.userPhotoUrl)
                              : null,
                          child: post.userPhotoUrl.isEmpty
                              ? Text(
                                  post.username.isNotEmpty
                                      ? post.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHint),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post.username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16)),
                              if (post.createdAt.isNotEmpty)
                                Text(post.createdAt.substring(0, 10),
                                    style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (post.caption.isNotEmpty) ...[
                    Text(post.caption, style: AppTextStyles.body),
                    const SizedBox(height: 16),
                  ],
                  if (post.garmentRefs.isNotEmpty) ...[
                    const Text('Pièces du fit',
                        style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Column(
                      children: post.garmentRefs.map<Widget>((ref) {
                        final text = [ref.brand, ref.name]
                            .where((s) => s.isNotEmpty)
                            .join(' - ');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.checkroom,
                                size: 20, color: AppColors.textHint),
                          ),
                          title: Text(text,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Friend requests sheet
// ---------------------------------------------------------------------------
class _FriendRequestsSheet extends ConsumerWidget {
  const _FriendRequestsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(receivedRequestsProvider);

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  Text('Demandes d\'amis', style: AppTextStyles.heading3),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: requestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('Aucune demande en attente',
                          style: AppTextStyles.bodySecondary),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final req = requests[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.divider,
                            backgroundImage: req.fromPhotoUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    req.fromPhotoUrl)
                                : null,
                            child: req.fromPhotoUrl.isEmpty
                                ? Text(
                                    req.fromUsername.isNotEmpty
                                        ? req.fromUsername[0]
                                            .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textHint),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.fromUsername,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                                const Text('Veut être ton ami',
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: AppColors.success, size: 28),
                            onPressed: () {
                              ref
                                  .read(friendshipNotifierProvider
                                      .notifier)
                                  .acceptRequest(req);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel,
                                color: AppColors.textHint, size: 28),
                            onPressed: () {
                              ref
                                  .read(friendshipNotifierProvider
                                      .notifier)
                                  .rejectRequest(req);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: Center(child: Text('Erreur: $e')),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
