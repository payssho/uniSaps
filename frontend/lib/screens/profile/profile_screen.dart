import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../models/garment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../widgets/stat_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _ProfileHeader(user: user),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textHint,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Stats'),
                Tab(text: 'Outfits'),
                Tab(text: 'Galerie'),
                Tab(text: 'Infos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _StatsTab(uid: user.uid, user: user),
                  _OutfitsTab(uid: user.uid),
                  _GalleryTab(uid: user.uid),
                  _InfosTab(user: user, onLogout: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  }),
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
        Text(
          user.displayName.isNotEmpty ? user.displayName : user.username,
          style: AppTextStyles.heading3,
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
                    childAspectRatio: constraints.maxWidth > 400 ? 1.3 : 1.2,
                    children: [
                      StatCard(label: 'Vetements', value: '${counts[0]}', icon: Icons.checkroom),
                      StatCard(label: 'Outfits', value: '${counts[1]}', icon: Icons.style, color: AppColors.secondary),
                      StatCard(label: 'Portes', value: '${counts[2]}', icon: Icons.done_all, color: AppColors.success),
                      StatCard(label: 'Streak', value: '${user.currentStreak}', icon: Icons.local_fire_department, color: AppColors.warning),
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
            return Container(
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
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${o.timesWorn}x',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent),
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
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
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
        final photos = outfits.expand((o) => o.photoUrls).toList();
        if (photos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library_outlined, size: 56, color: AppColors.textHint.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('Aucune photo', style: AppTextStyles.bodySecondary),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: photos.length,
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: photos[i],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.surfaceVariant,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image_outlined, color: AppColors.textHint),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
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
          _InfoRow(label: 'Membre depuis', value: user.createdAt.isNotEmpty ? user.createdAt.substring(0, 10) : '-'),
          _InfoRow(label: 'Meilleur streak', value: '${user.bestStreak} jours'),
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
          Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
