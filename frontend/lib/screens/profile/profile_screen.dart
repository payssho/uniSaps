import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../models/garment_model.dart';
import '../../models/outfit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/friendship_provider.dart';
import '../../widgets/stat_card.dart';
import '../inspiration/user_profile_screen.dart';
import '../inspiration/search_users_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final requestCount = ref.watch(receivedRequestsCountProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, top: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Retour',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 22, color: AppColors.textSecondary),
                    tooltip: 'Se deconnecter',
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _ProfileHeader(user: user),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textHint,
              indicatorSize: TabBarIndicatorSize.label,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: [
                const Tab(text: 'Stats'),
                const Tab(text: 'Outfits'),
                const Tab(text: 'Memories'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Amis'),
                      if (requestCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
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
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Infos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _StatsTab(uid: user.uid, user: user),
                  _OutfitsTab(uid: user.uid),
                  _GalleryTab(uid: user.uid),
                  _FriendsTab(user: user),
                  _InfosTab(
                    user: user,
                    onLogout: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.displayName.isNotEmpty ? user.displayName : user.username,
              style: AppTextStyles.heading3,
            ),
            if (user.isPrivate) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock_outline, size: 16, color: AppColors.textHint),
            ],
          ],
        ),
        if (user.username.isNotEmpty)
          Text('@${user.username}', style: AppTextStyles.bodySecondary),
      ],
    );
  }
}

class _StatsTab extends ConsumerWidget {
  final String uid;
  final UserModel user;

  const _StatsTab({required this.uid, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        ref.read(firestoreServiceProvider).garmentCount(uid),
        ref.read(firestoreServiceProvider).outfitCount(uid),
        ref.read(firestoreServiceProvider).wornOutfitCount(uid),
      ]),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? [0, 0, 0];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    // On donne un peu plus de hauteur aux cartes pour
                    // éviter les overflows verticaux sur les petits écrans.
                    childAspectRatio: constraints.maxWidth > 400 ? 1.15 : 0.95,
                    children: [
                      StatCard(label: 'Vetements', value: '${counts[0]}', icon: Icons.checkroom),
                      StatCard(
                          label: 'Outfits',
                          value: '${counts[1]}',
                          icon: Icons.style,
                          color: AppColors.secondary),
                      StatCard(
                          label: 'Portes',
                          value: '${counts[2]}',
                          icon: Icons.done_all,
                          color: AppColors.success),
                      StatCard(
                          label: 'Streak',
                          value: '${user.currentStreak}',
                          icon: Icons.local_fire_department,
                          color: AppColors.warning),
                    ],
                  );
                },
              ),
              if (user.bestStreak > 0) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Meilleur streak : ${user.bestStreak} jours',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _MostWornChart(uid: uid),
            ],
          ),
        );
      },
    );
  }
}

class _MostWornChart extends ConsumerWidget {
  final String uid;
  const _MostWornChart({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<GarmentModel>>(
      future: ref.read(firestoreServiceProvider).mostWornGarments(uid),
      builder: (context, snapshot) {
        final garments = snapshot.data ?? [];
        if (garments.isEmpty || garments.every((g) => g.timesWorn == 0)) {
          return const SizedBox.shrink();
        }
        final maxWorn = garments.map((g) => g.timesWorn).reduce((a, b) => a > b ? a : b);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Les plus portes', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            ...garments.where((g) => g.timesWorn > 0).map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: Text(
                          g.name,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: g.timesWorn / maxWorn,
                            backgroundColor: AppColors.surfaceVariant,
                            color: AppColors.accent,
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${g.timesWorn}',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _OutfitsTab extends ConsumerWidget {
  final String uid;
  const _OutfitsTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(outfitsProvider(uid));
    return outfitsAsync.when(
      data: (outfits) {
        final sorted = [...outfits]..sort((a, b) => b.timesWorn.compareTo(a.timesWorn));
        if (sorted.isEmpty) {
          return const Center(child: Text('Aucun outfit', style: AppTextStyles.bodySecondary));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final o = sorted[i];
            return GestureDetector(
              onTap: () => _showOutfitSummary(context, o),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${o.timesWorn}x',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent),
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
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (o.lastWorn.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('Dernier port : ${o.lastWorn}', style: AppTextStyles.caption),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

void _showOutfitSummary(BuildContext context, OutfitModel outfit) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OutfitSummarySheet(outfit: outfit),
  );
}

class _OutfitSummarySheet extends ConsumerWidget {
  final OutfitModel outfit;

  const _OutfitSummarySheet({required this.outfit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authServiceProvider).uid;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 4),
              if (outfit.lastWorn.isNotEmpty)
                Text('Dernier port : ${outfit.lastWorn}', style: AppTextStyles.caption),
              const SizedBox(height: 12),
              if (outfit.referencePhotoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CachedNetworkImage(
                    imageUrl: outfit.referencePhotoUrl,
                    fit: BoxFit.cover,
                    height: 220,
                    width: double.infinity,
                    placeholder: (_, __) => Container(
                      height: 220,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 220,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.textHint, size: 40),
                    ),
                  ),
                ),
              if (outfit.referencePhotoUrl.isNotEmpty) const SizedBox(height: 16),
              FutureBuilder<List<GarmentModel>>(
                future: ref.read(firestoreServiceProvider).mostWornGarments(uid),
                builder: (context, snapshot) {
                  // For now, just show garment ids; deep garment summary could be added later.
                  final garmentIds = outfit.garmentIds;
                  if (garmentIds.isEmpty) {
                    return const Text(
                      'Aucun vetement associe.',
                      style: AppTextStyles.bodySecondary,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pieces', style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: garmentIds
                            .map(
                              (id) => Chip(
                                label: Text(
                                  id,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryTab extends ConsumerWidget {
  final String uid;
  const _GalleryTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(outfitsProvider(uid));
    return outfitsAsync.when(
      data: (outfits) {
        // Construire une liste de memories (photo + meta outfit)
        final memories = <({String url, OutfitModel outfit})>[];
        for (final o in outfits) {
          for (final url in o.photoUrls) {
            memories.add((url: url, outfit: o));
          }
        }
        if (memories.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library_outlined,
                    size: 56, color: AppColors.textHint.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('Aucun souvenir pour l\'instant', style: AppTextStyles.bodySecondary),
              ],
            ),
          );
        }
        memories.sort(
          (a, b) => (b.outfit.lastWorn).compareTo(a.outfit.lastWorn),
        );
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: memories.length,
          itemBuilder: (_, i) {
            final memory = memories[i];
            final rawDate = memory.outfit.lastWorn.isNotEmpty
                ? memory.outfit.lastWorn
                : memory.outfit.createdAt;
            final date = rawDate.isNotEmpty && rawDate.length >= 10
                ? rawDate.substring(0, 10)
                : rawDate;
            return GestureDetector(
              onTap: () => _showMemoryDetail(context, memory.url, memory.outfit, date),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: memory.url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        date.isNotEmpty ? date : '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

void _showMemoryDetail(
  BuildContext context,
  String url,
  OutfitModel outfit,
  String date,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MemoryDetailSheet(
      url: url,
      outfit: outfit,
      date: date,
    ),
  );
}

class _MemoryDetailSheet extends StatelessWidget {
  final String url;
  final OutfitModel outfit;
  final String date;

  const _MemoryDetailSheet({
    required this.url,
    required this.outfit,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Row(
                children: [
                  Text(
                    date,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const Spacer(),
                  if (outfit.name.isNotEmpty)
                    Text(
                      outfit.name,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(
                    height: 320,
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 320,
                    color: AppColors.surfaceVariant,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textHint,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Photo prise lors du choix de l\'outfit du jour.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendsTab extends ConsumerStatefulWidget {
  final UserModel user;

  const _FriendsTab({required this.user});

  @override
  ConsumerState<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<_FriendsTab> {
  List<UserModel> _friendUsers = [];
  bool _loadingFriends = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void didUpdateWidget(covariant _FriendsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.friends.length != widget.user.friends.length) {
      _loadFriends();
    }
  }

  Future<void> _loadFriends() async {
    if (widget.user.friends.isEmpty) {
      setState(() {
        _friendUsers = [];
        _loadingFriends = false;
      });
      return;
    }
    final users = await ref.read(firestoreServiceProvider).getUsersByIds(widget.user.friends);
    if (mounted) {
      setState(() {
        _friendUsers = users;
        _loadingFriends = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(receivedRequestsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: SwitchListTile.adaptive(
              title: const Text(
                'Compte prive',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                widget.user.isPrivate
                    ? 'Seuls tes amis voient ton contenu'
                    : 'Tout le monde peut voir ton contenu',
                style: AppTextStyles.caption,
              ),
              secondary: Icon(
                widget.user.isPrivate ? Icons.lock_outline : Icons.public,
                color: widget.user.isPrivate ? AppColors.accent : AppColors.textHint,
              ),
              value: widget.user.isPrivate,
              activeColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onChanged: (val) {
                ref.read(friendshipNotifierProvider.notifier).togglePrivacy(val);
              },
            ),
          ),
          const SizedBox(height: 24),
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Demandes recues', style: AppTextStyles.heading3),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${requests.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...requests.map((req) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.surfaceVariant,
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
                              child: Text(
                                req.fromUsername,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: AppColors.success),
                              iconSize: 28,
                              onPressed: () {
                                ref.read(friendshipNotifierProvider.notifier).acceptRequest(req);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: AppColors.textHint),
                              iconSize: 28,
                              onPressed: () {
                                ref.read(friendshipNotifierProvider.notifier).rejectRequest(req);
                              },
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Row(
            children: [
              Text(
                'Mes amis (${widget.user.friends.length})',
                style: AppTextStyles.heading3,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchUsersScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_outlined,
                    size: 18, color: AppColors.accent),
                label: const Text(
                  'Ajouter un ami',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingFriends)
            const Center(child: CircularProgressIndicator())
          else if (_friendUsers.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(Icons.people_outline, size: 48, color: AppColors.textHint.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('Aucun ami pour le moment', style: AppTextStyles.bodySecondary),
                ],
              ),
            )
          else
            ...(_friendUsers.map((friend) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.surfaceVariant,
                      backgroundImage: friend.profilePhotoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(friend.profilePhotoUrl)
                          : null,
                      child: friend.profilePhotoUrl.isEmpty
                          ? Text(
                              friend.username.isNotEmpty
                                  ? friend.username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, color: AppColors.textHint),
                            )
                          : null,
                    ),
                    title: Text(
                      friend.username,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: friend.displayName.isNotEmpty
                        ? Text(friend.displayName, style: AppTextStyles.caption)
                        : null,
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textHint),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'view') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(userId: friend.uid),
                            ),
                          );
                        } else if (value == 'remove') {
                          _confirmRemove(friend);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                              SizedBox(width: 10),
                              Text('Voir le profil'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.person_remove, size: 18, color: AppColors.error),
                              SizedBox(width: 10),
                              Text('Retirer', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: friend.uid),
                        ),
                      );
                    },
                  ),
                ))),
        ],
      ),
    );
  }

  void _confirmRemove(UserModel friend) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Retirer cet ami ?'),
        content: Text('Retirer @${friend.username} de ta liste d\'amis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(friendshipNotifierProvider.notifier).removeFriend(friend.uid);
              setState(() {
                _friendUsers.removeWhere((u) => u.uid == friend.uid);
              });
            },
            child: const Text('Retirer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _InfosTab extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const _InfosTab({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _InfoRow(label: 'Email', value: user.email),
          _InfoRow(label: 'Pseudo', value: user.username),
          _InfoRow(label: 'Nom', value: user.displayName),
          _InfoRow(
              label: 'Membre depuis',
              value: user.createdAt.isNotEmpty ? user.createdAt.substring(0, 10) : '-'),
          _InfoRow(label: 'Meilleur streak', value: '${user.bestStreak} jours'),
          _InfoRow(label: 'Amis', value: '${user.friends.length}'),
          _InfoRow(label: 'Compte', value: user.isPrivate ? 'Prive' : 'Public'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: onLogout,
              child: const Text('Se deconnecter'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodySecondary),
          const Spacer(),
          Text(value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
