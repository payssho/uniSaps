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
import '../../widgets/post_card.dart';
import 'search_users_screen.dart';
import 'user_profile_screen.dart';

class InspirationScreen extends ConsumerStatefulWidget {
  const InspirationScreen({super.key});

  @override
  ConsumerState<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends ConsumerState<InspirationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).uid;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final requestCount = ref.watch(receivedRequestsCountProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Inspiration', style: AppTextStyles.heading2),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_add_outlined, size: 24),
                        color: AppColors.textSecondary,
                        tooltip: 'Demandes d\'amis',
                        onPressed: () => _showFriendRequests(context),
                      ),
                      if (requestCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$requestCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, size: 24),
                    color: AppColors.textSecondary,
                    tooltip: 'Rechercher',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(10),
                tabs: const [
                  Tab(text: 'Amis'),
                  Tab(text: 'Explorer'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FriendsTab(uid: uid, user: user),
                  _ExploreTab(uid: uid, user: user),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton.extended(
          heroTag: 'inspiration_fab',
          backgroundColor: AppColors.accent,
          elevation: 6,
          onPressed: () => _showPublishSheet(context),
          icon: const Icon(Icons.add, color: Colors.white, size: 24),
          label: const Text('Publier',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
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
        const SnackBar(
          content: Text('Pour publier, choisis d\'abord un outfit du jour et prends la photo.'),
        ),
      );
      return;
    }

    final uid = ref.read(authServiceProvider).uid;
    try {
      final outfit = await ref.read(firestoreServiceProvider).getOutfit(uid, user.dailyOutfitId);
      if (outfit == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de recuperer l\'outfit du jour.')),
        );
        return;
      }

      final garments = <GarmentModel>[];
      for (final gid in outfit.garmentIds) {
        final g = await ref.read(firestoreServiceProvider).getGarment(uid, gid);
        if (g != null) garments.add(g);
      }

      if (!mounted) return;
      _showDailyPostSheet(context, user, outfit, garments);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la preparation du post.')),
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
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Publier l\'outfit du jour', style: AppTextStyles.heading3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
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
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
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
                    final text = [g.brand, g.name].where((s) => s.isNotEmpty).join(' - ');
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
              const SizedBox(height: 14),
              TextField(
                controller: captionController,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Legende (optionnel)...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref.read(postNotifierProvider.notifier).createPostFromDaily(
                          user: user,
                          outfit: outfit,
                          garments: garments,
                          caption: captionController.text.trim(),
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Publier l\'outfit du jour',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

class _FriendsTab extends ConsumerWidget {
  final String uid;
  final UserModel? user;

  const _FriendsTab({required this.uid, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(friendsPostsProvider);

    return postsAsync.when(
      data: (posts) {
        if (user != null && user!.friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 72, color: AppColors.textHint.withValues(alpha: 0.3)),
                const SizedBox(height: 20),
                const Text('Aucun ami pour le moment', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                const Text(
                  'Recherche des utilisateurs pour les ajouter !',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
                    );
                  },
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Trouver des amis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.article_outlined, size: 72, color: AppColors.textHint.withValues(alpha: 0.3)),
                const SizedBox(height: 20),
                const Text('Aucun post de tes amis', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 6),
                const Text('Tes amis n\'ont pas encore publie.', style: AppTextStyles.caption),
              ],
            ),
          );
        }

        return _PostsList(posts: posts, uid: uid);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _ExploreTab extends ConsumerWidget {
  final String uid;
  final UserModel? user;

  const _ExploreTab({required this.uid, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return postsAsync.when(
      data: (allPosts) {
        final friends = user?.friends ?? [];
        final visiblePosts = allPosts.where((post) {
          if (post.userId == uid) return true;
          if (friends.contains(post.userId)) return true;
          return true;
        }).toList();

        if (visiblePosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_outlined, size: 72, color: AppColors.textHint.withValues(alpha: 0.3)),
                const SizedBox(height: 20),
                const Text('Aucun post', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 6),
                const Text('Sois le premier a partager !', style: AppTextStyles.caption),
              ],
            ),
          );
        }

        return _PostsList(posts: visiblePosts, uid: uid);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _PostsList extends ConsumerWidget {
  final List<PostModel> posts;
  final String uid;

  const _PostsList({required this.posts, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (_, i) => PostCard(
        post: posts[i],
        currentUid: uid,
        onLike: () {
          ref.read(postNotifierProvider.notifier).toggleLike(posts[i].id, uid);
        },
        onTap: () => _showPostDetails(context, posts[i]),
        onUserTap: () => _showUserProfile(context, posts[i].userId),
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

  void _showUserProfile(BuildContext context, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    );
  }
}

class _PostDetailSheet extends StatelessWidget {
  final PostModel post;

  const _PostDetailSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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
              color: AppColors.textHint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: post.userId),
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
                                  post.username.isNotEmpty ? post.username[0].toUpperCase() : '?',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textHint),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post.username,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              if (post.createdAt.isNotEmpty)
                                Text(post.createdAt.substring(0, 10), style: AppTextStyles.caption),
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
                            child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2)),
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
                    const Text('Pieces du fit', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Column(
                      children: post.garmentRefs.map<Widget>((ref) {
                        final text = [ref.brand, ref.name].where((s) => s.isNotEmpty).join(' - ');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.checkroom, size: 20, color: AppColors.textHint),
                          ),
                          title: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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

class _FriendRequestsSheet extends ConsumerWidget {
  const _FriendRequestsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(receivedRequestsProvider);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
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
              color: AppColors.textHint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Demandes d\'amis', style: AppTextStyles.heading3),
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
                      child: Text('Aucune demande en attente', style: AppTextStyles.bodySecondary),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                        fontWeight: FontWeight.w600, color: AppColors.textHint),
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
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                const Text(
                                  'Veut etre ton ami',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                            onPressed: () {
                              ref.read(friendshipNotifierProvider.notifier).acceptRequest(req);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: AppColors.textHint, size: 28),
                            onPressed: () {
                              ref.read(friendshipNotifierProvider.notifier).rejectRequest(req);
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
