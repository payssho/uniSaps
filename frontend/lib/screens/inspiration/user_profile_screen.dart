import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/garment_model.dart';
import '../../models/outfit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friendship_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post_card.dart';

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
    final db = ref.read(firestoreServiceProvider);
    final myUser = ref.read(currentUserProvider).valueOrNull;

    final user = await db.getUser(widget.userId);
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    RelationshipStatus rel = RelationshipStatus.none;
    if (myUser != null) {
      if (myUser.friends.contains(user.uid)) {
        rel = RelationshipStatus.friends;
      } else {
        final sent = await db.findPendingRequest(myUser.uid, user.uid);
        if (sent != null) {
          rel = RelationshipStatus.requestSent;
        } else {
          final received = await db.findPendingRequest(user.uid, myUser.uid);
          if (received != null) {
            rel = RelationshipStatus.requestReceived;
          }
        }
      }
    }

    final canSeeContent = !user.isPrivate || rel == RelationshipStatus.friends;
    var posts = <PostModel>[];
    var garments = <GarmentModel>[];
    var outfits = <OutfitModel>[];

    if (canSeeContent) {
      posts = await db.getUserPosts(user.uid);
      garments = await db.getGarments(user.uid);
      outfits = await db.getOutfits(user.uid);
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
  }

  Future<void> _sendRequest() async {
    final myUser = ref.read(currentUserProvider).valueOrNull;
    if (myUser == null || _targetUser == null) return;
    setState(() => _actionLoading = true);
    await ref.read(friendshipNotifierProvider.notifier).sendRequest(
          from: myUser,
          to: _targetUser!,
        );
    setState(() {
      _relationship = RelationshipStatus.requestSent;
      _actionLoading = false;
    });
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
                    _OutfitsTab(outfits: _outfits),
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
                      Text('Prive', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          CircleAvatar(
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
              _StatBadge(value: '${user.friends.length}', label: 'Amis'),
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
          icon: const Icon(Icons.person_add, size: 18, color: Colors.white),
          label: const Text('Accepter', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
      case RelationshipStatus.none:
        button = ElevatedButton.icon(
          onPressed: _sendRequest,
          icon: const Icon(Icons.person_add_outlined, size: 18, color: Colors.white),
          label: const Text('Ajouter en ami', style: TextStyle(color: Colors.white)),
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
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;

  const _StatBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: AppTextStyles.caption),
      ],
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
            Icon(Icons.article_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('Aucun post', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => PostCard(
        post: posts[i],
        currentUid: uid,
        onLike: () => ref.read(postNotifierProvider.notifier).toggleLike(posts[i].id, uid),
        onTap: () => _showPostDetails(context, posts[i]),
      ),
    );
  }

  void _showPostDetails(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimplePostDetail(post: post),
    );
  }
}

class _SimplePostDetail extends StatelessWidget {
  final PostModel post;
  const _SimplePostDetail({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.textHint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  if (post.caption.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(post.caption, style: AppTextStyles.body),
                  ],
                  if (post.garmentRefs.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ...post.garmentRefs.map((r) {
                      final text = [r.brand, r.name].where((s) => s.isNotEmpty).join(' - ');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.checkroom, size: 16, color: AppColors.textHint),
                            const SizedBox(width: 8),
                            Text(text, style: AppTextStyles.caption),
                          ],
                        ),
                      );
                    }),
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

class _DressingTab extends StatelessWidget {
  final List<GarmentModel> garments;

  const _DressingTab({required this.garments});

  @override
  Widget build(BuildContext context) {
    if (garments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('Dressing vide', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: garments.length,
      itemBuilder: (_, i) {
        final g = garments[i];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: g.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: g.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.broken_image_outlined, color: AppColors.textHint),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.checkroom, color: AppColors.textHint),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  g.name.isNotEmpty ? g.name : g.brand,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutfitsTab extends StatelessWidget {
  final List<OutfitModel> outfits;

  const _OutfitsTab({required this.outfits});

  @override
  Widget build(BuildContext context) {
    if (outfits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.3)),
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
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${o.timesWorn}x',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  o.name.isEmpty ? 'Outfit' : o.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
