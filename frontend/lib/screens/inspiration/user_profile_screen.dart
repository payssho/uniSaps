import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/friend_request_model.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/garment_model.dart';
import '../../models/outfit_model.dart';
import '../../models/collection_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friendship_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/post_detail_sheet.dart';
import '../../widgets/premium_avatar_ring.dart';
import '../../widgets/garment_category_glyph.dart';
import '../../widgets/garment_card.dart';
import '../../widgets/garment_detail_sheet.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/outfit_detail_sheet.dart';
import '../../widgets/user_list_tile.dart';
import '../../widgets/dressing_category_chips_row.dart';
import '../../widgets/dressing_category_filters_bar.dart';
import '../../widgets/storage_aware_cached_image.dart';
import '../../core/constants/categories.dart';
import '../../utils/dressing_garment_filters.dart';
import '../../utils/post_garment_image_prefetch.dart';
import '../../l10n/l10n_context.dart';

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
  List<CollectionModel> _collections = [];

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Recréé uniquement pendant [_loading] (pas de TabBar monté) pour éviter crash / dirty build.
  void _syncTabController(UserModel user) {
    final len = user.isCreator ? 2 : 3;
    if (_tabController != null && _tabController!.length == len) return;
    final index = (_tabController?.index ?? 0).clamp(0, len - 1);
    _tabController?.dispose();
    _tabController = TabController(
      length: len,
      vsync: this,
      initialIndex: index,
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
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
      var collections = <CollectionModel>[];

      if (canSeeContent) {
        try {
          posts = await db.getUserPosts(user.uid);
          garments = await db.getGarments(user.uid);
          if (user.isCreator) {
            collections = await db.getCollections(user.uid);
          } else {
          outfits = await db.getOutfits(user.uid);
          }
        } catch (_) {
          // Contenu inaccessible - on affiche le profil vide
        }
      }

      if (mounted) {
        _syncTabController(user);
        setState(() {
          _targetUser = user;
          _relationship = rel;
          _posts = posts;
          _garments = garments;
          _outfits = outfits;
          _collections = collections;
          _loading = false;
        });
        if (posts.isNotEmpty && garments.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            // ignore: discarded_futures
            prefetchProfilePostGarmentImages(
              context: context,
              posts: posts,
              ownerGarments: garments,
              ownerOutfits: outfits,
            );
          });
        }
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
                  Text(context.l10n.inspoFriendRequestSentExclaim(_targetUser!.username),
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
          content: Text(context.l10n.commonErrorDetail(e)),
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
        body: Center(child: Text(context.l10n.userProfileNotFound, style: AppTextStyles.bodySecondary)),
      );
    }

    final user = _targetUser!;
    final isCreatorProfile = user.isCreator;
    final tabCount = isCreatorProfile ? 2 : 3;
    final canSeeContent = !user.isPrivate || _relationship == RelationshipStatus.friends;
    final myUid = ref.watch(authServiceProvider).uid;
    final isMe = myUid == user.uid;
    final tabsReady =
        _tabController != null && _tabController!.length == tabCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user, isMe),
            if (!isMe) _buildActionButton(),
            if ((canSeeContent || isMe) && tabsReady) ...[
              TabBar(
                controller: _tabController!,
                indicatorColor: AppColors.accent,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textHint,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: AppColors.divider,
                tabs: isCreatorProfile
                    ? const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Collections'),
                      ]
                    : const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Dressing'),
                  Tab(text: 'Outfits'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController!,
                  children: isCreatorProfile
                      ? [
                          _PostsTab(
                            posts: _posts,
                            uid: myUid,
                            ownerGarments: _garments,
                            ownerOutfits: _outfits,
                          ),
                          _CreatorCollectionsTab(
                            collections: _collections,
                            garments: _garments,
                          ),
                        ]
                      : [
                          _PostsTab(
                            posts: _posts,
                            uid: myUid,
                            ownerGarments: _garments,
                            ownerOutfits: _outfits,
                          ),
                    _DressingTab(garments: _garments),
                          _OutfitsTab(
                            outfits: _outfits,
                            ownerUid: user.uid,
                            garments: _garments,
                          ),
                  ],
                ),
              ),
            ] else if (canSeeContent || isMe) ...[
              const Expanded(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(context.l10n.userProfilePrivate, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          _ProfileAvatar(user: user),
          const SizedBox(height: 12),
          Text(
            user.displayName.isNotEmpty ? user.displayName : user.username,
            style: AppTextStyles.heading3,
          ),
          if (user.username.isNotEmpty)
            Text(context.l10n.userAtUsername(user.username), style: AppTextStyles.bodySecondary),
          if (user.isCreator) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_rounded, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Créateur',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (user.creatorBio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  user.creatorBio,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySecondary,
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: user.isCreator
                ? [
                    _StatBadge(value: '${_posts.length}', label: context.l10n.creatorTabPosts),
                    const SizedBox(width: 28),
                    _StatBadge(
                      value: '${_collections.length}',
                      label: context.l10n.userProfileCollections,
                    ),
                    const SizedBox(width: 28),
                    _StatBadge(value: '${_garments.length}', label: context.l10n.signupCreatorCatalogPieces),
                  ]
                : [
              _StatBadge(
                value: '${user.friends.length}',
                label: context.l10n.inspoFeedFriends,
                onTap: () => _openProfileFriendsList(user, isMe),
              ),
              const SizedBox(width: 28),
              _StatBadge(value: '${user.currentStreak}', label: context.l10n.statStreak),
              const SizedBox(width: 28),
              _StatBadge(value: '${user.bestStreak}', label: context.l10n.statBest),
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
          label: Text(context.l10n.userProfileFriend, style: TextStyle(color: AppColors.success)),
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
          label: Text(context.l10n.userProfileRequestSent),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
      case RelationshipStatus.requestReceived:
        button = ElevatedButton.icon(
          onPressed: _acceptRequest,
          icon: const Icon(Icons.person_add, size: 18, color: AppColors.white),
          label: Text(context.l10n.userProfileAccept, style: TextStyle(color: AppColors.white)),
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
          label: Text(context.l10n.userProfileAddFriend, style: TextStyle(color: AppColors.white)),
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
        title: Text(context.l10n.profileRemoveFriendTitle),
        content: Text(
          'Retirer @${_targetUser!.username} de ta liste d\'amis ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeFriend();
            },
            child: Text(context.l10n.profileRemoveFriendAction, style: TextStyle(color: AppColors.error)),
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

class _ProfileAvatar extends StatelessWidget {
  final UserModel user;

  const _ProfileAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    const radius = 44.0;
    const size = radius * 2;
    final url = user.displayAvatarUrl;

    Widget fallback() {
      if (user.isCreator) {
        return const Icon(Icons.storefront_rounded, size: 40, color: AppColors.primary);
      }
      return Text(
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textHint,
        ),
      );
    }

    return PremiumAvatarRing(
      isPremium: user.isPremium,
      padding: 4,
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: ColoredBox(
            color: AppColors.surfaceVariant,
            child: url.isNotEmpty
                ? StorageAwareCachedImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    preferHighQuality: true,
                    loadingWidget: const Center(
                      child: SizedBox(
                        width: size * 0.35,
                        height: size * 0.35,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __) => Center(child: fallback()),
                  )
                : Center(child: fallback()),
          ),
        ),
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
                        child: Text(context.l10n.userProfileFriendsLoadFailed(snap.error!), style: AppTextStyles.bodySecondary),
                      ),
                    );
                  }
                  final friends = _orderLikeProfile(snap.data ?? []);
                  if (friends.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.people_outline,
                      title: 'Aucun ami pour le moment',
                      size: AppEmptyStateSize.compact,
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
                          trailing = Text(context.l10n.userProfileFriend, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success));
                        } else if (pendingSent != null) {
                          trailing = Text(context.l10n.userProfilePending, style: AppTextStyles.caption.copyWith(color: AppColors.textHint));
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
                                  child: Text(context.l10n.userProfileAccept),
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
                                  child: Text(context.l10n.creationAddZone),
                                );
                        }
                      }

                      return UserListTile(
                        user: u,
                        prefixAtUsername: true,
                        bordered: false,
                        onTap: () => _goToProfile(u),
                        trailing: isSelf
                            ? Text(context.l10n.inspoChipYou,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textHint))
                            : trailing,
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
  final List<GarmentModel> ownerGarments;
  final List<OutfitModel> ownerOutfits;

  const _PostsTab({
    required this.posts,
    required this.uid,
    required this.ownerGarments,
    required this.ownerOutfits,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (posts.isEmpty) {
      return const AppEmptyState(
        icon: Icons.article_outlined,
        title: 'Aucun post',
        size: AppEmptyStateSize.compact,
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
        ownerGarments: ownerGarments,
        ownerOutfits: ownerOutfits,
        onLike: () => ref.read(postNotifierProvider.notifier).toggleLike(posts[i].id, uid),
        onTap: () => _showPostDetails(context, posts[i]),
      ),
    );
  }

  void _showPostDetails(BuildContext context, PostModel post) {
    PostDetailSheet.show(
      context,
      post,
      ownerGarments: ownerGarments,
      ownerOutfits: ownerOutfits,
      showAuthorHeader: false,
    );
  }
}

/// Collections créateur (profil public), triées de la plus récente à la plus ancienne.
class _CreatorCollectionsTab extends StatelessWidget {
  final List<CollectionModel> collections;
  final List<GarmentModel> garments;

  const _CreatorCollectionsTab({
    required this.collections,
    required this.garments,
  });

  static int _sortKey(CollectionModel c) {
    final created = DateTime.tryParse(c.createdAt);
    if (created != null) return created.millisecondsSinceEpoch;
    final end = DateTime.tryParse(c.endDate);
    if (end != null) return end.millisecondsSinceEpoch;
    return 0;
  }

  Map<String, List<GarmentModel>> _groupGarments() {
    final map = <String, List<GarmentModel>>{};
    for (final g in garments) {
      final key = g.collectionId.isNotEmpty ? g.collectionId : '_none';
      map.putIfAbsent(key, () => []).add(g);
    }
    return map;
  }

  void _openGarment(BuildContext context, GarmentModel g) {
    GarmentDetailSheet.show(
      context,
      garment: g,
      mode: GarmentDetailMode.readOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<CollectionModel>.from(collections)
      ..sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));
    final grouped = _groupGarments();

    if (sorted.isEmpty) {
      return const AppEmptyState(
        icon: Icons.collections_bookmark_outlined,
        title: 'Aucune collection',
        subtitle: 'Ce créateur n’a pas encore publié de collection.',
        size: AppEmptyStateSize.compact,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final col = sorted[index];
        final items = grouped[col.id] ?? <GarmentModel>[];
        return _CreatorPublicCollectionCard(
          collection: col,
          garments: items,
          onGarmentTap: (g) => _openGarment(context, g),
        );
      },
    );
  }
}

class _CreatorPublicCollectionCard extends StatelessWidget {
  final CollectionModel collection;
  final List<GarmentModel> garments;
  final void Function(GarmentModel) onGarmentTap;

  const _CreatorPublicCollectionCard({
    required this.collection,
    required this.garments,
    required this.onGarmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = garments.length;
    final dateLine = collection.startDate.isNotEmpty
        ? '${collection.startDate} → ${collection.endDate}'
        : '';
    final recentLabel = collection.createdAt.length >= 10
        ? collection.createdAt.substring(0, 10)
        : collection.createdAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
        color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: AppColors.graphite.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
                  width: 4,
            decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.accent,
                        AppColors.primary.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                        Row(
                          children: [
                            Icon(
                              Icons.collections_bookmark_rounded,
                              size: 18,
                              color: AppColors.accent.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                collection.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (recentLabel.isNotEmpty)
                              _CollectionMetaChip(
                                icon: Icons.schedule_rounded,
                                label: context.l10n.userProfileAddedOn(recentLabel),
                              ),
                            if (dateLine.isNotEmpty)
                              _CollectionMetaChip(
                                icon: Icons.calendar_month_rounded,
                                label: dateLine,
                              ),
                            _CollectionMetaChip(
                              icon: Icons.checkroom_rounded,
                              label: count == 1 ? '1 pièce' : '$count pièces',
                              accent: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (garments.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: Text(
                  'Aucune pièce dans cette collection pour le moment.',
                  style: AppTextStyles.caption,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: garments.length.clamp(0, 6),
                  itemBuilder: (_, i) {
                    final g = garments[i];
                    return GarmentCard(
                      garment: g,
                      onTap: () => onGarmentTap(g),
                    );
                  },
                ),
              ),
            if (garments.length > 6)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text(
                  '+ ${garments.length - 6} autre${garments.length - 6 > 1 ? 's' : ''} pièce${garments.length - 6 > 1 ? 's' : ''}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _CollectionMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _CollectionMetaChip({
    required this.icon,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.95)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.95),
            ),
          ),
          ],
        ),
      );
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

  List<GarmentModel> _garmentsForFilterOptions() {
    if (_selectedCategory.isEmpty) return widget.garments;
    return _garmentsInCategory(_selectedCategory);
  }

  List<GarmentModel> _applyFilters(List<GarmentModel> list) {
    return applyDressingGarmentFilters(
      list: list,
      nameFilter: _nameFilter,
      brandFilter: _brandFilter,
      colorFilter: _colorFilter,
    );
  }

  List<GarmentModel> _filteredForCategory(String categoryKey) {
    return _applyFilters(_garmentsInCategory(categoryKey));
  }

  void _showReadOnlyGarment(BuildContext context, GarmentModel g) {
    GarmentDetailSheet.show(
      context,
      garment: g,
      mode: GarmentDetailMode.readOnly,
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

  Widget _buildGroupedByCategory({required bool noFilters}) {
    final sections = <Widget>[];
    for (final cat in categories) {
      final items = _applyFilters(_garmentsInCategory(cat.key));
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
    if (sections.isEmpty) {
      return _emptyState(
        hasItemsInCat: widget.garments.isNotEmpty,
        noFilters: noFilters,
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
            Text(context.l10n.userProfileEmptyDressing, style: AppTextStyles.bodySecondary),
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
        const SizedBox(height: 10),
        DressingCategoryFiltersBar(
          nameController: _nameFilterController,
          brandFilter: _brandFilter,
          colorFilter: _colorFilter,
          garmentsForOptions: _garmentsForFilterOptions(),
          onNameChanged: (v) => setState(() => _nameFilter = v),
          onBrandChanged: (v) => setState(() => _brandFilter = v ?? ''),
          onColorChanged: (v) => setState(() => _colorFilter = v ?? ''),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _selectedCategory.isEmpty
              ? _buildGroupedByCategory(noFilters: noFilters)
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
      return const AppEmptyState(
        icon: Icons.style_outlined,
        title: 'Aucun outfit',
        size: AppEmptyStateSize.compact,
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
    final cache = {for (final g in garments) g.id: g};
    OutfitDetailSheet.show(
      context,
          outfit: outfit,
      garmentCache: cache,
      mode: OutfitDetailMode.readOnly,
    );
  }
}
