import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/friend_request_model.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/garment_model.dart';
import '../../models/outfit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friendship_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/post_detail_sheet.dart';
import '../../widgets/premium_avatar_ring.dart';
import '../../widgets/garment_category_glyph.dart';
import '../../widgets/garment_card.dart';
import '../../widgets/garment_colors_wrap.dart';
import '../../widgets/dressing_category_chips_row.dart';
import '../../widgets/dressing_category_filters_bar.dart';
import '../../widgets/storage_aware_cached_image.dart';
import '../../core/constants/categories.dart';
import '../../utils/dressing_garment_filters.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  UserModel? _targetUser;
  bool _loading = true;
  RelationshipStatus _relationship = RelationshipStatus.none;
  bool _actionLoading = false;

  List<PostModel> _posts = [];
  List<GarmentModel> _garments = [];
  List<OutfitModel> _outfits = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final db = ref.read(firestoreServiceProvider);

      // Attendre que le currentUser soit disponible (max 5s)
      UserModel? myUser = ref.read(currentUserProvider).valueOrNull;
      if (myUser == null) {
        for (var i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          myUser = ref.read(currentUserProvider).valueOrNull;
          if (myUser != null) break;
        }
      }

      final user = await db.getUser(widget.userId);
      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      RelationshipStatus rel = RelationshipStatus.none;
      if (myUser != null) {
        if (myUser.friends.contains(user.uid)) {
          rel = RelationshipStatus.friends;
        } else {
          try {
            final sent = await db.findPendingRequest(myUser.uid, user.uid);
            if (sent != null) {
              rel = RelationshipStatus.requestSent;
            } else {
              final received = await db.findPendingRequest(user.uid, myUser.uid);
              if (received != null) {
                rel = RelationshipStatus.requestReceived;
              }
            }
          } catch (_) {
            // Index Firestore potentiellement manquant - on reste à RelationshipStatus.none
          }
        }
      }

      final canSeeContent = !user.isPrivate || rel == RelationshipStatus.friends;
      var posts = <PostModel>[];
      var garments = <GarmentModel>[];
      var outfits = <OutfitModel>[];

      if (canSeeContent) {
        try {
          posts = await db.getUserPosts(user.uid);
          garments = await db.getGarments(user.uid);
          outfits = await db.getOutfits(user.uid);
        } catch (_) {
          // Contenu inaccessible - on affiche le profil vide
        }
      }

      if (mounted) {
        setState(() {
          _targetUser = user;
          _relationship = rel;
          _posts = posts;
          _garments = garments;
          _outfits = outfits;
          _loading = false;
        });
      }
    } catch (e) {
      // Erreur générale : on sort du loading pour ne pas bloquer l'UI
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendRequest() async {
    final myUser = ref.read(currentUserProvider).valueOrNull;
    if (myUser == null || _targetUser == null) return;
    setState(() => _actionLoading = true);
    try {
      final ok = await ref.read(friendshipNotifierProvider.notifier).sendRequest(
            from: myUser,
            to: _targetUser!,
          );
      if (!mounted) return;
      setState(() {
        _relationship = RelationshipStatus.requestSent;
        _actionLoading = false;
      });
      if (ok) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.white, size: 18),
                  const SizedBox(width: 10),
                  Text('Demande envoyée à @${_targetUser!.username} !',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              duration: const Duration(seconds: 3),
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _acceptRequest() async {
    final db = ref.read(firestoreServiceProvider);
    final myUser = ref.read(currentUserProvider).valueOrNull;
    if (myUser == null || _targetUser == null) return;
    setState(() => _actionLoading = true);
    final request = await db.findPendingRequest(_targetUser!.uid, myUser.uid);
    if (request != null) {
      await ref.read(friendshipNotifierProvider.notifier).acceptRequest(request);
    }
    setState(() {
      _relationship = RelationshipStatus.friends;
      _actionLoading = false;
    });
    _loadProfile();
  }

  Future<void> _removeFriend() async {
    setState(() => _actionLoading = true);
    await ref.read(friendshipNotifierProvider.notifier).removeFriend(_targetUser!.uid);
    setState(() {
      _relationship = RelationshipStatus.none;
      _actionLoading = false;
    });
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_targetUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Utilisateur introuvable', style: AppTextStyles.bodySecondary)),
      );
    }

    final user = _targetUser!;
    final canSeeContent = !user.isPrivate || _relationship == RelationshipStatus.friends;
    final myUid = ref.watch(authServiceProvider).uid;
    final isMe = myUid == user.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user, isMe),
            if (!isMe) _buildActionButton(),
            if (canSeeContent || isMe) ...[
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accent,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textHint,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: AppColors.divider,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Dressing'),
                  Tab(text: 'Outfits'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PostsTab(posts: _posts, uid: myUid),
                    _DressingTab(garments: _garments),
                    _OutfitsTab(
                      outfits: _outfits,
                      ownerUid: user.uid,
                      garments: _garments,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_outline, size: 36, color: AppColors.textHint),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Compte prive',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ajoute cet utilisateur en ami pour voir son contenu.',
                          style: AppTextStyles.bodySecondary,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user, bool isMe) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              if (user.isPrivate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: AppColors.textHint),
                      SizedBox(width: 4),
                      Text('Privé', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          PremiumAvatarRing(
            isPremium: user.isPremium,
            padding: 4,
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage:
                  user.profilePhotoUrl.isNotEmpty ? CachedNetworkImageProvider(user.profilePhotoUrl) : null,
              child: user.profilePhotoUrl.isEmpty
                  ? Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textHint),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.displayName.isNotEmpty ? user.displayName : user.username,
            style: AppTextStyles.heading3,
          ),
          if (user.username.isNotEmpty)
            Text('@${user.username}', style: AppTextStyles.bodySecondary),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBadge(
                value: '${user.friends.length}',
                label: 'Amis',
                onTap: () => _openProfileFriendsList(user, isMe),
              ),
              const SizedBox(width: 28),
              _StatBadge(value: '${user.currentStreak}', label: 'Streak'),
              const SizedBox(width: 28),
              _StatBadge(value: '${user.bestStreak}', label: 'Best'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_actionLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    Widget button;
    switch (_relationship) {
      case RelationshipStatus.friends:
        button = OutlinedButton.icon(
          onPressed: () => _showRemoveDialog(),
          icon: const Icon(Icons.check, size: 18, color: AppColors.success),
          label: const Text('Ami', style: TextStyle(color: AppColors.success)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.success),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
      case RelationshipStatus.requestSent:
        button = OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_empty, size: 18),
          label: const Text('Demande envoyee'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
      case RelationshipStatus.requestReceived:
        button = ElevatedButton.icon(
          onPressed: _acceptRequest,
          icon: const Icon(Icons.person_add, size: 18, color: AppColors.white),
          label: const Text('Accepter', style: TextStyle(color: AppColors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
      case RelationshipStatus.none:
        button = ElevatedButton.icon(
          onPressed: _sendRequest,
          icon: const Icon(Icons.person_add_outlined, size: 18, color: AppColors.white),
          label: const Text('Ajouter en ami', style: TextStyle(color: AppColors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: button,
    );
  }

  void _showRemoveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Retirer cet ami ?'),
        content: Text(
          'Retirer @${_targetUser!.username} de ta liste d\'amis ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeFriend();
            },
            child: const Text('Retirer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _openProfileFriendsList(UserModel profileUser, bool isMe) {
    final hostCtx = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileFriendsSheet(
        profileUser: profileUser,
        showAddActions: !isMe,
        hostContext: hostCtx,
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatBadge({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: AppTextStyles.caption),
      ],
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: child,
        ),
      ),
    );
  }
}

/// Liste des amis d’un profil (tap sur le compteur « Amis ») - ajout possible depuis chaque ligne.
class _ProfileFriendsSheet extends ConsumerStatefulWidget {
  final UserModel profileUser;
  final bool showAddActions;
  final BuildContext hostContext;

  const _ProfileFriendsSheet({
    required this.profileUser,
    required this.showAddActions,
    required this.hostContext,
  });

  @override
  ConsumerState<_ProfileFriendsSheet> createState() => _ProfileFriendsSheetState();
}

class _ProfileFriendsSheetState extends ConsumerState<_ProfileFriendsSheet> {
  Future<List<UserModel>>? _friendsFuture;
  String? _actingUid;

  FriendRequestModel? _sentTo(List<FriendRequestModel> sent, String uid) {
    for (final r in sent) {
      if (r.toUid == uid) return r;
    }
    return null;
  }

  FriendRequestModel? _receivedFrom(List<FriendRequestModel> recv, String uid) {
    for (final r in recv) {
      if (r.fromUid == uid) return r;
    }
    return null;
  }

  List<UserModel> _orderLikeProfile(List<UserModel> loaded) {
    final byId = {for (final u in loaded) u.uid: u};
    return widget.profileUser.friends
        .map((id) => byId[id])
        .whereType<UserModel>()
        .toList();
  }

  Future<void> _sendRequest(UserModel to) async {
    final my = ref.read(currentUserProvider).valueOrNull;
    if (my == null) return;
    setState(() => _actingUid = to.uid);
    try {
      await ref.read(friendshipNotifierProvider.notifier).sendRequest(from: my, to: to);
    } finally {
      if (mounted) setState(() => _actingUid = null);
    }
  }

  Future<void> _acceptRequest(FriendRequestModel request) async {
    setState(() => _actingUid = request.fromUid);
    try {
      await ref.read(friendshipNotifierProvider.notifier).acceptRequest(request);
    } finally {
      if (mounted) setState(() => _actingUid = null);
    }
  }

  void _goToProfile(UserModel u) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.hostContext.mounted) return;
      Navigator.of(widget.hostContext).push(
        MaterialPageRoute<void>(
          builder: (_) => UserProfileScreen(userId: u.uid),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(firestoreServiceProvider);
    _friendsFuture ??= db.getUsersByIds(widget.profileUser.friends);

    final myUser = ref.watch(currentUserProvider).valueOrNull;
    final sent = ref.watch(sentRequestsProvider).valueOrNull ?? [];
    final recv = ref.watch(receivedRequestsProvider).valueOrNull ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.profileUser.username.isNotEmpty
                          ? 'Amis de @${widget.profileUser.username}'
                          : 'Amis',
                      style: AppTextStyles.heading3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _friendsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Impossible de charger la liste : ${snap.error}', style: AppTextStyles.bodySecondary),
                      ),
                    );
                  }
                  final friends = _orderLikeProfile(snap.data ?? []);
                  if (friends.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Aucun ami pour le moment', style: AppTextStyles.bodySecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    itemCount: friends.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (_, i) {
                      final u = friends[i];
                      final isSelf = myUser != null && u.uid == myUser.uid;
                      final isFriend = myUser != null && myUser.friends.contains(u.uid);
                      final pendingSent = _sentTo(sent, u.uid);
                      final pendingRecv = _receivedFrom(recv, u.uid);
                      final busy = _actingUid == u.uid;

                      Widget? trailing;
                      if (widget.showAddActions && myUser != null && !isSelf) {
                        if (isFriend) {
                          trailing = const Text('Ami', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success));
                        } else if (pendingSent != null) {
                          trailing = Text('En attente', style: AppTextStyles.caption.copyWith(color: AppColors.textHint));
                        } else if (pendingRecv != null) {
                          trailing = busy
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : TextButton(
                                  onPressed: () => _acceptRequest(pendingRecv),
                                  child: const Text('Accepter'),
                                );
                        } else {
                          trailing = busy
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : TextButton(
                                  onPressed: () => _sendRequest(u),
                                  child: const Text('Ajouter'),
                                );
                        }
                      }

                      return InkWell(
                        onTap: () => _goToProfile(u),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.surfaceVariant,
                                backgroundImage: u.profilePhotoUrl.isNotEmpty ? CachedNetworkImageProvider(u.profilePhotoUrl) : null,
                                child: u.profilePhotoUrl.isEmpty
                                    ? Text(
                                        u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textHint),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u.username.isNotEmpty ? '@${u.username}' : u.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (u.displayName.isNotEmpty && u.username.isNotEmpty)
                                      Text(u.displayName, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              if (isSelf)
                                Text('Toi', style: AppTextStyles.caption.copyWith(color: AppColors.textHint))
                              else if (trailing != null)
                                trailing,
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsTab extends ConsumerWidget {
  final List<PostModel> posts;
  final String uid;

  const _PostsTab({required this.posts, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 56, color: AppColors.textHint.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text('Aucun post', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.52,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) => PostCard(
        post: posts[i],
        currentUid: uid,
        layout: PostCardLayout.grid,
        onLike: () => ref.read(postNotifierProvider.notifier).toggleLike(posts[i].id, uid),
        onTap: () => _showPostDetails(context, posts[i]),
      ),
    );
  }

  void _showPostDetails(BuildContext context, PostModel post) {
    PostDetailSheet.show(context, post);
  }
}

class _DressingTab extends StatefulWidget {
  final List<GarmentModel> garments;

  const _DressingTab({required this.garments});

  @override
  State<_DressingTab> createState() => _DressingTabState();
}

class _DressingTabState extends State<_DressingTab> {
  String _selectedCategory = '';
  final TextEditingController _nameFilterController = TextEditingController();
  String _nameFilter = '';
  String _brandFilter = '';
  String _colorFilter = '';

  static const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 180,
    childAspectRatio: 0.72,
    crossAxisSpacing: 14,
    mainAxisSpacing: 14,
  );

  @override
  void dispose() {
    _nameFilterController.dispose();
    super.dispose();
  }

  void _setCategory(String key) {
    setState(() {
      _selectedCategory = key;
      _nameFilter = '';
      _nameFilterController.clear();
      _brandFilter = '';
      _colorFilter = '';
    });
  }

  List<GarmentModel> _garmentsInCategory(String categoryKey) {
    return widget.garments.where((g) => g.category == categoryKey).toList();
  }

  List<GarmentModel> _filteredForCategory(String categoryKey) {
    final byCat = _garmentsInCategory(categoryKey);
    return applyDressingGarmentFilters(
      list: byCat,
      nameFilter: _nameFilter,
      brandFilter: _brandFilter,
      colorFilter: _colorFilter,
    );
  }

  void _showReadOnlyGarment(BuildContext context, GarmentModel g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReadOnlyGarmentSheet(garment: g),
    );
  }

  Widget _garmentGrid(List<GarmentModel> items) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      gridDelegate: _gridDelegate,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final g = items[i];
        return GarmentCard(
          garment: g,
          onTap: () => _showReadOnlyGarment(context, g),
        );
      },
    );
  }

  Widget _emptyState({required bool hasItemsInCat, required bool noFilters}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 56,
            color: AppColors.textHint.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            hasItemsInCat && !noFilters ? 'Aucun résultat' : 'Aucun vêtement',
            style: AppTextStyles.bodySecondary,
          ),
          if (hasItemsInCat && !noFilters) ...[
            const SizedBox(height: 6),
            const Text(
              'Essaie un autre nom, marque ou couleur.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupedByCategory() {
    final sections = <Widget>[];
    for (final cat in categories) {
      final items = _garmentsInCategory(cat.key);
      if (items.isEmpty) continue;
      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Row(
            children: [
              GarmentCategoryGlyph(
                categoryKey: cat.key,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                cat.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      );
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: _gridDelegate,
            itemCount: items.length,
            itemBuilder: (_, i) {
              final g = items[i];
              return GarmentCard(
                garment: g,
                onTap: () => _showReadOnlyGarment(context, g),
              );
            },
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: sections,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.garments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 56,
              color: AppColors.textHint.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            const Text('Dressing vide', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    final noFilters = _nameFilter.trim().isEmpty &&
        _brandFilter.isEmpty &&
        _colorFilter.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        DressingCategoryChipsRow(
          selectedCategory: _selectedCategory,
          onCategorySelected: _setCategory,
        ),
        if (_selectedCategory.isNotEmpty) ...[
          const SizedBox(height: 10),
          DressingCategoryFiltersBar(
            nameController: _nameFilterController,
            brandFilter: _brandFilter,
            colorFilter: _colorFilter,
            garmentsForOptions: _garmentsInCategory(_selectedCategory),
            onNameChanged: (v) => setState(() => _nameFilter = v),
            onBrandChanged: (v) => setState(() => _brandFilter = v ?? ''),
            onColorChanged: (v) => setState(() => _colorFilter = v ?? ''),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: _selectedCategory.isEmpty
              ? _buildGroupedByCategory()
              : Builder(
                  builder: (context) {
                    final byCat = _garmentsInCategory(_selectedCategory);
                    final filtered = _filteredForCategory(_selectedCategory);
                    if (filtered.isEmpty) {
                      return _emptyState(
                        hasItemsInCat: byCat.isNotEmpty,
                        noFilters: noFilters,
                      );
                    }
                    return _garmentGrid(filtered);
                  },
                ),
        ),
      ],
    );
  }
}

class _OutfitsTab extends StatelessWidget {
  final List<OutfitModel> outfits;
  final String ownerUid;
  final List<GarmentModel> garments;

  const _OutfitsTab({
    required this.outfits,
    required this.ownerUid,
    required this.garments,
  });

  static String _thumbUrl(OutfitModel o) {
    if (o.referencePhotoUrl.isNotEmpty) return o.referencePhotoUrl;
    if (o.photoUrls.isNotEmpty) return o.photoUrls.first;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (outfits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_outlined, size: 56, color: AppColors.textHint.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text('Aucun outfit', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: outfits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final o = outfits[i];
        final thumb = _thumbUrl(o);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showFriendOutfitDetail(context, o),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: thumb.isNotEmpty
                          ? StorageAwareCachedImage(
                              imageUrl: thumb,
                              fit: BoxFit.cover,
                              loadingWidget:
                                  Container(color: AppColors.surfaceVariant),
                              errorWidget: (_, __) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(
                                  Icons.style_rounded,
                                  color: AppColors.textHint,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.surfaceVariant,
                              alignment: Alignment.center,
                              child: const Icon(Icons.style_rounded, color: AppColors.textHint),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          o.name.isEmpty ? 'Outfit' : o.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (o.lastWorn.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Dernier port : ${o.lastWorn}',
                              style: AppTextStyles.caption,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${o.timesWorn}x',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFriendOutfitDetail(BuildContext context, OutfitModel outfit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FriendOutfitDetailSheet(
        outfit: outfit,
        ownerGarments: garments,
      ),
    );
  }
}

/// Détail outfit d’un autre utilisateur : photo principale + pièces résolues.
class _FriendOutfitDetailSheet extends StatelessWidget {
  final OutfitModel outfit;
  final List<GarmentModel> ownerGarments;

  const _FriendOutfitDetailSheet({
    required this.outfit,
    required this.ownerGarments,
  });

  String get _heroUrl {
    if (outfit.referencePhotoUrl.isNotEmpty) return outfit.referencePhotoUrl;
    if (outfit.photoUrls.isNotEmpty) return outfit.photoUrls.first;
    return '';
  }

  List<GarmentModel> _resolvePieces() {
    if (outfit.garmentIds.isEmpty) return [];
    final byId = {for (final g in ownerGarments) g.id: g};
    return outfit.garmentIds
        .map((id) => byId[id])
        .whereType<GarmentModel>()
        .toList();
  }

  void _openGarmentDetail(BuildContext context, GarmentModel g) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReadOnlyGarmentSheet(garment: g),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pieces = _resolvePieces();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                outfit.name.isEmpty ? 'Outfit' : outfit.name,
                style: AppTextStyles.heading3,
              ),
              if (outfit.lastWorn.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Dernier port : ${outfit.lastWorn}', style: AppTextStyles.caption),
              ],
              const SizedBox(height: 14),
              if (_heroUrl.isNotEmpty)
                GestureDetector(
                  onTap: () => _openPhotoFullScreen(context, _heroUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: StorageAwareCachedImage(
                      imageUrl: _heroUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 260,
                      loadingWidget: Container(
                        height: 260,
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __) => Container(
                        height: 260,
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.photo_library_outlined, size: 40, color: AppColors.textHint),
                ),
              if (outfit.photoUrls.length > 1) ...[
                const SizedBox(height: 14),
                const Text('Autres photos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: outfit.photoUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final url = outfit.photoUrls[i];
                      return GestureDetector(
                        onTap: () => _openPhotoFullScreen(context, url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 88,
                            height: 88,
                            child: StorageAwareCachedImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              loadingWidget:
                                  Container(color: AppColors.surfaceVariant),
                              errorWidget: (_, __) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textHint,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (pieces.isEmpty)
                const Text('Aucune pièce liée', style: AppTextStyles.bodySecondary)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pièces', style: AppTextStyles.heading3),
                    const SizedBox(height: 10),
                    ...pieces.map((g) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openGarmentDetail(context, g),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: g.imageUrl.isNotEmpty
                                          ? StorageAwareCachedImage(
                                              imageUrl: g.imageUrl,
                                              fit: BoxFit.cover,
                                              loadingWidget: Container(
                                                color: AppColors.surfaceVariant,
                                              ),
                                              errorWidget: (_, __) => Container(
                                                color: AppColors.surfaceVariant,
                                                child: Center(
                                                  child: GarmentCategoryGlyph(
                                                    categoryKey: g.category,
                                                    color: AppColors.textHint,
                                                    size: 28,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: AppColors.surfaceVariant,
                                              child: Center(
                                                child: GarmentCategoryGlyph(
                                                  categoryKey: g.category,
                                                  color: AppColors.textHint,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.name.isNotEmpty ? g.name : 'Sans nom',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (g.brand.isNotEmpty)
                                          Text(g.brand, style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPhotoFullScreen(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dCtx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black87,
        child: GestureDetector(
          onTap: () => Navigator.pop(dCtx),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: StorageAwareCachedImage(
              imageUrl: url,
              fit: BoxFit.contain,
              loadingWidget: const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                ),
              ),
              errorWidget: (_, __) => const Icon(
                Icons.broken_image_outlined,
                color: AppColors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Détail dressing en lecture seule (profil ami).
class _ReadOnlyGarmentSheet extends StatelessWidget {
  final GarmentModel garment;

  const _ReadOnlyGarmentSheet({required this.garment});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            GestureDetector(
              onTap: garment.imageUrl.isNotEmpty
                  ? () {
                      showDialog<void>(
                        context: context,
                        builder: (dCtx) => Dialog(
                          insetPadding: const EdgeInsets.all(12),
                          backgroundColor: Colors.black87,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(dCtx),
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4,
                              child: StorageAwareCachedImage(
                                imageUrl: garment.imageUrl,
                                fit: BoxFit.contain,
                                loadingWidget: const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 260,
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                  child: garment.imageUrl.isNotEmpty
                      ? StorageAwareCachedImage(
                          imageUrl: garment.imageUrl,
                          fit: BoxFit.cover,
                          loadingWidget: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (_, __) => Center(
                            child: GarmentCategoryGlyph(
                              categoryKey: garment.category,
                              size: 56,
                              color: AppColors.textHint,
                            ),
                          ),
                        )
                      : Center(
                          child: GarmentCategoryGlyph(
                            categoryKey: garment.category,
                            size: 56,
                            color: AppColors.textHint,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GarmentCategoryGlyph(
                        categoryKey: garment.category,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        categoryLabel(garment.category),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
                if (garment.timesWorn > 0) ...[
                  const SizedBox(width: 10),
                  Text('${garment.timesWorn}x porté', style: AppTextStyles.caption),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              garment.name.isNotEmpty ? garment.name : 'Sans nom',
              style: AppTextStyles.heading3,
            ),
            if (garment.brand.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(garment.brand, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ],
            if (garment.colors.isNotEmpty) ...[
              const SizedBox(height: 12),
              GarmentColorsWrap(colors: garment.colors, fontSize: 12),
            ],
          ],
        ),
      ),
    );
  }
}
