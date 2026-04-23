import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/garment_model.dart';
import '../../models/outfit_model.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/friendship_provider.dart';
import '../home/home_screen.dart';
import 'search_users_screen.dart';
import 'user_profile_screen.dart';

class InspirationScreen extends ConsumerStatefulWidget {
  const InspirationScreen({super.key});

  @override
  ConsumerState<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends ConsumerState<InspirationScreen> {
  final _horizontalPageController = PageController();
  bool _showFriends = true;
  bool _showScrollHint = false;
  bool _scrollHintChecked = false;

  @override
  void dispose() {
    _horizontalPageController.dispose();
    super.dispose();
  }

  void _checkScrollHint() {
    if (_scrollHintChecked) return;
    _scrollHintChecked = true;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final seen = user.tutorialSeen.inspiration;
    if (!seen) {
      setState(() => _showScrollHint = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _dismissScrollHint();
      });
    }
  }

  void _dismissScrollHint() {
    if (!_showScrollHint) return;
    setState(() => _showScrollHint = false);
    final uid = ref.read(authServiceProvider).uid;
    if (uid.isEmpty) return;
    ref.read(firestoreServiceProvider).updateUser(uid, {
      'tutorial_seen.inspiration': true,
    });
  }

  void _toggleFeed(bool friends) {
    if (_showFriends == friends) return;
    setState(() => _showFriends = friends);
    _horizontalPageController.animateToPage(
      friends ? 0 : 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).uid;
    final user = ref.watch(currentUserProvider).valueOrNull;

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollHint());

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Horizontal PageView: Amis / Explorer (swipeable)
          PageView(
            controller: _horizontalPageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _showFriends = i == 0),
            children: [
              _FriendsFeed(
                uid: uid,
                user: user,
                onDoubleTap: (post) => _handleDoubleTapLike(post, uid),
                onScrollStart: _dismissScrollHint,
              ),
              _ExploreFeed(
                uid: uid,
                user: user,
                onDoubleTap: (post) => _handleDoubleTapLike(post, uid),
                onScrollStart: _dismissScrollHint,
              ),
            ],
          ),

          // Top overlay: toggle
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _FeedToggle(
                  showFriends: _showFriends,
                  onToggle: _toggleFeed,
                ),
              ],
            ),
          ),

          // Publish FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: _PublishButton(onTap: () => _handlePublish(context)),
          ),

          // Scroll hint overlay (first visit only)
          if (_showScrollHint)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 200),
                      Icon(Icons.keyboard_arrow_down,
                              color: Colors.white.withOpacity(0.7), size: 48)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(
                              begin: 0,
                              end: 14,
                              duration: 800.ms,
                              curve: Curves.easeInOut),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Swipe pour voir plus',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleDoubleTapLike(PostModel post, String uid) {
    if (!post.isLikedBy(uid)) {
      ref.read(postNotifierProvider.notifier).toggleLike(post.id, uid);
    }
  }

  void _handlePublish(BuildContext context) {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    if (user.dailyOutfitId.isEmpty || user.dailyPhotoUrl.isEmpty) {
      // Redirect to Outfits tab (index 1) with explanatory SnackBar
      ref.read(selectedTabProvider.notifier).state = 1;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('Choisis d\'abord ton outfit du jour'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accent.withOpacity(0.92),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      return;
    }

    _showPublishSheet(context, user);
  }

  Future<void> _showPublishSheet(BuildContext context, dynamic user) async {
    final uid = ref.read(authServiceProvider).uid;
    try {
      final outfit = await ref
          .read(firestoreServiceProvider)
          .getOutfit(uid, user.dailyOutfitId);
      if (outfit == null || !mounted) return;

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
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                outfit.name.isNotEmpty ? outfit.name : 'Mon outfit du jour',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
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
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final ok = await ref
                        .read(postNotifierProvider.notifier)
                        .createPostFromDaily(
                          user: user,
                          outfit: outfit,
                          garments: garments,
                          caption: captionController.text.trim(),
                        );
                    if (!mounted) return;
                    if (ok) {
                      // Basculer sur Explorer pour voir son post en premier
                      _toggleFeed(false);
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 10),
                                Text('Outfit publié !',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            margin:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Erreur lors de la publication.')),
                      );
                    }
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
              label: 'Amis', active: showFriends, onTap: () => onToggle(true)),
          _ToggleChip(
              label: 'Explorer',
              active: !showFriends,
              onTap: () => onToggle(false)),
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
// Friends feed
// ---------------------------------------------------------------------------
class _FriendsFeed extends ConsumerWidget {
  final String uid;
  final UserModel? user;
  final void Function(PostModel) onDoubleTap;
  final VoidCallback onScrollStart;

  const _FriendsFeed({
    required this.uid,
    required this.user,
    required this.onDoubleTap,
    required this.onScrollStart,
  });

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

        // Ne garder que les posts du jour courant
        final now = DateTime.now();
        final todayPosts = posts.where((p) {
          final dt = DateTime.tryParse(p.createdAt);
          if (dt == null) return false;
          return dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day;
        }).toList();

        if (todayPosts.isEmpty) {
          return const _EmptyFeedMessage(
            icon: Icons.article_outlined,
            title: 'Aucun post de tes amis aujourd\'hui',
            subtitle: 'Reviens demain ou invite tes amis à publier.',
          );
        }

        return _FullScreenFeed(
          posts: todayPosts,
          uid: uid,
          onDoubleTap: onDoubleTap,
          onScrollStart: onScrollStart,
        );
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
// Explore feed
// ---------------------------------------------------------------------------
class _ExploreFeed extends ConsumerWidget {
  final String uid;
  final UserModel? user;
  final void Function(PostModel) onDoubleTap;
  final VoidCallback onScrollStart;

  const _ExploreFeed({
    required this.uid,
    required this.user,
    required this.onDoubleTap,
    required this.onScrollStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return postsAsync.when(
      data: (posts) {
        final now = DateTime.now();
        final todayPosts = posts.where((p) {
          final dt = DateTime.tryParse(p.createdAt);
          if (dt == null) return false;
          return dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day;
        }).toList();

        // Mon post en premier
        todayPosts.sort((a, b) {
          if (a.userId == uid && b.userId != uid) return -1;
          if (b.userId == uid && a.userId != uid) return 1;
          return 0;
        });

        if (todayPosts.isEmpty) {
          return const _EmptyFeedMessage(
            icon: Icons.explore_outlined,
            title: 'Aucun post aujourd\'hui',
            subtitle: 'Sois le premier à partager ton outfit du jour !',
          );
        }
        return _FullScreenFeed(
          posts: todayPosts,
          uid: uid,
          onDoubleTap: onDoubleTap,
          onScrollStart: onScrollStart,
        );
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
  final void Function(PostModel) onDoubleTap;
  final VoidCallback onScrollStart;

  const _FullScreenFeed({
    required this.posts,
    required this.uid,
    required this.onDoubleTap,
    required this.onScrollStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (_) {
        onScrollStart();
        return false;
      },
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        // +1 pour la slide de fin "reviens demain"
        itemCount: posts.length + 1,
        itemBuilder: (context, index) {
          if (index >= posts.length) {
            return const _EndOfDayMessage();
          }
          final post = posts[index];
          return _FullScreenPost(
            post: post,
            uid: uid,
            onLike: () {
              ref
                  .read(postNotifierProvider.notifier)
                  .toggleLike(post.id, uid);
            },
            onDoubleTap: () => onDoubleTap(post),
            onUserTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: post.userId),
                ),
              );
            },
            onDelete: post.userId == uid
                ? () => ref
                    .read(postNotifierProvider.notifier)
                    .deletePost(post.id)
                : null,
            onEditCaption: post.userId == uid
                ? (caption) => ref
                    .read(postNotifierProvider.notifier)
                    .updateCaption(post.id, caption)
                : null,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// End-of-day slide
// ---------------------------------------------------------------------------
class _EndOfDayMessage extends StatelessWidget {
  const _EndOfDayMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black87,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.wb_twighlight, size: 56, color: Colors.white70),
              SizedBox(height: 16),
              Text(
                'Tu as vu tous les looks du jour',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Reviens demain pour decouvrir de nouveaux outfits !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single full-screen post with double-tap like animation
// ---------------------------------------------------------------------------
class _FullScreenPost extends StatefulWidget {
  final PostModel post;
  final String uid;
  final VoidCallback onLike;
  final VoidCallback onDoubleTap;
  final VoidCallback onUserTap;
  final VoidCallback? onDelete;
  final void Function(String)? onEditCaption;

  const _FullScreenPost({
    required this.post,
    required this.uid,
    required this.onLike,
    required this.onDoubleTap,
    required this.onUserTap,
    this.onDelete,
    this.onEditCaption,
  });

  @override
  State<_FullScreenPost> createState() => _FullScreenPostState();
}

class _FullScreenPostState extends State<_FullScreenPost>
    with SingleTickerProviderStateMixin {
  bool _showHeart = false;
  late bool _liked;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLikedBy(widget.uid);
    _likes = widget.post.likes;
  }

  @override
  void didUpdateWidget(covariant _FullScreenPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likes != widget.post.likes ||
        oldWidget.uid != widget.uid) {
      _liked = widget.post.isLikedBy(widget.uid);
      _likes = widget.post.likes;
    }
  }

  void _handleDoubleTap() {
    // Optimistic UI: toggle like locally immediately
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
      if (_likes < 0) _likes = 0;
      _showHeart = true;
    });

    widget.onDoubleTap();
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          if (widget.post.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.post.imageUrl,
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

          // Menu 3-points (mes posts seulement)
          if (widget.post.userId == widget.uid)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: GestureDetector(
                onTap: () => _showPostMenu(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert,
                      color: Colors.white, size: 22),
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
                GestureDetector(
                  onTap: widget.onUserTap,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: widget.post.userPhotoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(
                              widget.post.userPhotoUrl)
                          : null,
                      child: widget.post.userPhotoUrl.isEmpty
                          ? Text(
                              widget.post.username.isNotEmpty
                                  ? widget.post.username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    // Optimistic UI: toggle like locally
                    setState(() {
                      _liked = !_liked;
                      _likes += _liked ? 1 : -1;
                      if (_likes < 0) _likes = 0;
                    });
                    widget.onLike();
                  },
                  child: Column(
                    children: [
                      Icon(
                        _liked ? Icons.favorite : Icons.favorite_border,
                        color: _liked ? AppColors.accent : Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_likes',
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
                if (widget.post.garmentRefs.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showPostDetails(context, widget.post),
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

          // Bottom info
          Positioned(
            bottom: 40,
            left: 16,
            right: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: widget.onUserTap,
                  child: Text(
                    '@${widget.post.username}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (widget.post.caption.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.post.caption,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (widget.post.garmentRefs.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.post.garmentRefs.take(3).map((ref) {
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

          // Double-tap heart animation
          if (_showHeart)
            Center(
              child: Icon(
                Icons.favorite,
                color: Colors.white.withOpacity(0.85),
                size: 100,
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1.1, 1.1),
                    duration: 250.ms,
                    curve: Curves.easeOutBack,
                  )
                  .then(delay: 300.ms)
                  .fadeOut(duration: 350.ms),
            ),
        ],
      ),
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

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.accent),
              title: const Text('Modifier la légende'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditCaptionDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Supprimer le post',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Supprimer le post ?'),
                    content: const Text('Cette action est irréversible.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(d, true),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.error),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) widget.onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCaptionDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.post.caption);
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifier la légende'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          minLines: 1,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Légende...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(d);
              widget.onEditCaption?.call(controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
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
                              ? CachedNetworkImageProvider(post.userPhotoUrl)
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
// Social sheet (Friend requests + Search merged)
// ---------------------------------------------------------------------------
class _SocialSheet extends ConsumerStatefulWidget {
  const _SocialSheet();

  @override
  ConsumerState<_SocialSheet> createState() => _SocialSheetState();
}

class _SocialSheetState extends ConsumerState<_SocialSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results =
          await ref.read(firestoreServiceProvider).searchUsers(query.trim());
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(receivedRequestsProvider);

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
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
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textHint,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Demandes'),
                    if ((requestsAsync.valueOrNull?.length ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${requestsAsync.valueOrNull?.length ?? 0}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Rechercher'),
            ],
          ),
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Friend requests
                _buildRequestsTab(requestsAsync),
                // Tab 2: Search
                _buildSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(AsyncValue<dynamic> requestsAsync) {
    return requestsAsync.when(
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                        ? CachedNetworkImageProvider(req.fromPhotoUrl)
                        : null,
                    child: req.fromPhotoUrl.isEmpty
                        ? Text(
                            req.fromUsername.isNotEmpty
                                ? req.fromUsername[0].toUpperCase()
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
                        Text(
                          req.fromUsername,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
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
                          .read(friendshipNotifierProvider.notifier)
                          .acceptRequest(req);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel,
                        color: AppColors.textHint, size: 28),
                    onPressed: () {
                      ref
                          .read(friendshipNotifierProvider.notifier)
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
    );
  }

  Widget _buildSearchTab() {
    final uid = ref.read(authServiceProvider).uid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textHint),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onChanged: _search,
          ),
        ),
        if (_searching)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Tape un nom pour chercher'
                          : 'Aucun résultat',
                      style: AppTextStyles.bodySecondary,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    itemCount: _searchResults.length,
                    itemBuilder: (_, i) {
                      final u = _searchResults[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 4),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.surfaceVariant,
                          backgroundImage: u.profilePhotoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  u.profilePhotoUrl)
                              : null,
                          child: u.profilePhotoUrl.isEmpty
                              ? Text(
                                  u.username.isNotEmpty
                                      ? u.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHint),
                                )
                              : null,
                        ),
                        title: Text(u.username,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        trailing: u.uid == uid
                            ? const Chip(label: Text('Toi'))
                            : IconButton(
                                icon: const Icon(Icons.person_add_outlined,
                                    color: AppColors.accent),
                                onPressed: () {
                                  final me = ref.read(currentUserProvider).valueOrNull;
                                  if (me != null) {
                                    ref
                                        .read(friendshipNotifierProvider
                                            .notifier)
                                        .sendRequest(from: me, to: u);
                                  }
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Demande envoyée à ${u.username}'),
                                      behavior:
                                          SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  12)),
                                    ),
                                  );
                                },
                              ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserProfileScreen(userId: u.uid),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
