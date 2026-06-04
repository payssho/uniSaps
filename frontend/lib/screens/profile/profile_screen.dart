import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/premium_unlock.dart';
import '../../models/user_model.dart';
import '../../models/garment_model.dart';
import '../../models/outfit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/garment_provider.dart';
import '../../providers/friendship_provider.dart';
import '../../widgets/premium_avatar_ring.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/outfit_detail_sheet.dart';
import '../../widgets/storage_aware_cached_image.dart';
import '../../widgets/async_error_state.dart';
import '../../widgets/stat_row.dart';
import '../../widgets/user_list_tile.dart';
import '../../widgets/language_locale_button.dart';
import '../../providers/ui_navigation_provider.dart';
import '../../l10n/l10n_context.dart';
import '../inspiration/user_profile_screen.dart';
import 'style_preferences_screen.dart';
import '../inspiration/search_users_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  /// Quand true (onglet racine Home), pas de bouton retour qui ferait pop la mauvaise route.
  final bool embeddedInMainNav;

  const ProfileScreen({
    super.key,
    this.embeddedInMainNav = false,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  /// Indique s’il reste du contenu scrollable vers le bas dans l’onglet actif.
  bool _scrollMoreBelow = false;
  bool _friendRequestSnackShown = false;

  static const int _tabAmis = 1;
  static const int _tabCompte = 2;

  int get _tabCount => _ProfileTabRail.entries.length;

  void _goToFriendsTab() {
    if (!mounted) return;
    _tabController.animateTo(_tabAmis);
  }

  void _initTabController({int? initialIndex}) {
    final count = _tabCount;
    final idx = (initialIndex ?? 0).clamp(0, count - 1);
    _tabController = TabController(
      length: count,
      vsync: this,
      initialIndex: idx,
    );
    _tabController.addListener(_onProfileTabChanged);
  }

  void _syncTabControllerAfterStructureChange() {
    if (_tabController.length == _tabCount) return;
    final idx = _tabController.index.clamp(0, _tabCount - 1);
    _tabController.removeListener(_onProfileTabChanged);
    _tabController.dispose();
    _initTabController(initialIndex: idx);
  }

  @override
  void initState() {
    super.initState();
    _initTabController();
  }

  @override
  void reassemble() {
    super.reassemble();
    _syncTabControllerAfterStructureChange();
  }

  void _onProfileTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_scrollMoreBelow) {
      setState(() => _scrollMoreBelow = false);
    }
  }

  bool _onProfileTabScrollOrMetrics(Notification notification) {
    final ScrollMetrics? m;
    if (notification is ScrollNotification) {
      m = notification.metrics;
    } else if (notification is ScrollMetricsNotification) {
      m = notification.metrics;
    } else {
      return false;
    }
    if (m.axis != Axis.vertical) return false;
    if (!m.hasPixels || !m.hasViewportDimension) return false;

    final canScrollDown =
        m.maxScrollExtent > 12 && m.pixels < m.maxScrollExtent - 12;
    if (canScrollDown != _scrollMoreBelow) {
      setState(() => _scrollMoreBelow = canScrollDown);
    }
    return false;
  }

  @override
  void dispose() {
    _tabController.removeListener(_onProfileTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final requestCount = ref.watch(receivedRequestsCountProvider);

    ref.listen<int>(receivedRequestsCountProvider, (prev, next) {
      if (!widget.embeddedInMainNav || next <= 0) return;
      if (prev != null && prev > 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || user == null) return;
        _goToFriendsTab();
        if (!_friendRequestSnackShown) {
          _friendRequestSnackShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nouvelle demande d’ami'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    });

    ref.listen(profileInfosTabRequestProvider, (prev, next) {
      if (next == (prev ?? 0)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.animateTo(_tabCompte);
      });
    });

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Précharge la liste d’amis dès l’ouverture du profil.
    ref.watch(friendUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.embeddedInMainNav)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 16, top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Retour',
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      widget.embeddedInMainNav ? 4 : 10,
                      16,
                      12,
                    ),
                    child: _ProfileHero(
                      embeddedInMainNav: widget.embeddedInMainNav,
                      user: user,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _ProfileTabRail(
                      controller: _tabController,
                      pendingFriendRequests: requestCount,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        NotificationListener<Notification>(
                          onNotification: _onProfileTabScrollOrMetrics,
                          child: TabBarView(
                            key: ValueKey<int>(_tabCount),
                            controller: _tabController,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _GalleryTab(uid: user.uid),
                              _FriendsTab(user: user),
                              _AccountTab(
                                user: user,
                                onLogout: () async {
                                  await ref
                                      .read(authNotifierProvider.notifier)
                                      .signOut();
                                  if (context.mounted) context.go('/login');
                                },
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 56,
                          child: AnimatedOpacity(
                            opacity: _scrollMoreBelow ? 1 : 0,
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.background.withValues(
                                          alpha: 0),
                                      AppColors.background
                                          .withValues(alpha: 0.45),
                                      AppColors.background
                                          .withValues(alpha: 0.92),
                                    ],
                                    stops: const [0.0, 0.35, 1.0],
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons
                                              .keyboard_arrow_down_rounded,
                                          size: 26,
                                          color: AppColors.textHint
                                              .withValues(alpha: 0.8),
                                        )
                                            .animate(
                                              onPlay: (c) =>
                                                  c.repeat(reverse: true),
                                            )
                                            .moveY(
                                              begin: 0,
                                              end: 5,
                                              duration: 750.ms,
                                              curve: Curves.easeInOutCubic,
                                            ),
                                        Text(
                                          'Fais défiler',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.1,
                                            color: AppColors.textHint
                                                .withValues(alpha: 0.65),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _ProfileHero extends ConsumerWidget {
  final UserModel user;
  /// Aligne le bloc avec les autres onglets (Sans bande retour + moins de marge haute).
  final bool embeddedInMainNav;

  const _ProfileHero({
    required this.user,
    this.embeddedInMainNav = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName =
        user.displayName.isNotEmpty ? user.displayName : user.username;
    final initials = user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : (displayName.isNotEmpty ? displayName[0].toUpperCase() : '?');
    return Material(
      color: Colors.transparent,
      elevation: 0,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (user.isPremium)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFE082),
                      AppColors.accent.withValues(alpha: 0.95),
                      const Color(0xFFE65100),
                    ],
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cardGradientStart,
                    AppColors.surface,
                    AppColors.accent.withValues(alpha: 0.14),
                    AppColors.primary.withValues(alpha: 0.07),
                  ],
                  stops: const [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -28,
            right: -36,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -16,
            child: IgnorePointer(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              embeddedInMainNav ? 12 : 20,
              18,
              18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    user.isPremium
                        ? PremiumAvatarRing(
                            isPremium: true,
                            padding: 4,
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: AppColors.surfaceVariant,
                              backgroundImage:
                                  user.profilePhotoUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          user.profilePhotoUrl)
                                      : null,
                              child: user.profilePhotoUrl.isEmpty
                                  ? Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textHint,
                                      ),
                                    )
                                  : null,
                            ),
                          )
                        : Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              AppColors.accent.withValues(alpha: 0.45),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.scrimLight,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.surfaceVariant,
                        backgroundImage:
                            user.profilePhotoUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    user.profilePhotoUrl)
                                : null,
                        child: user.profilePhotoUrl.isEmpty
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textHint,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: AppTextStyles.heading2.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.isPremium)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6, top: 2),
                                  child: Tooltip(
                                    message: 'Compte UniSaps+',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFFFB300),
                                            AppColors.accent
                                                .withValues(alpha: 0.95),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.22),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.workspace_premium_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'UniSaps+',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (user.isPrivate) ...[
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: 'Profil privé',
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.lock_rounded,
                                      size: 20,
                                      color: AppColors.textHint
                                          .withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (user.username.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '@${user.username}',
                                style: AppTextStyles.bodySecondary.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          _ProfileStreakBadge(days: user.currentStreak),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ProfileHeroStats(uid: user.uid, user: user),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Série de jours : flamme + chiffre (pas de style bouton).
class _ProfileStreakBadge extends StatelessWidget {
  final int days;

  const _ProfileStreakBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          size: 28,
          color: const Color(0xFFFF6D00),
          shadows: [
            Shadow(
              color: const Color(0xFFFF6D00).withValues(alpha: 0.45),
              blurRadius: 8,
            ),
          ],
        ),
        const SizedBox(width: 6),
        Text(
          '$days',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          days <= 1 ? 'jour' : 'jours',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

/// Stats compactes dans la carte profil (ex-onglet Stats).
class _ProfileHeroStats extends ConsumerWidget {
  final String uid;
  final UserModel user;

  const _ProfileHeroStats({required this.uid, required this.user});

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
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.75),
                ),
              ),
              child: Row(
                children: [
                  StatCell(
                    label: 'Vêtements',
                    value: loading ? '—' : '${counts[0]}',
                    icon: Icons.checkroom_outlined,
                    color: AppColors.accent,
                  ),
                  statRowDivider(),
                  StatCell(
                    label: 'Outfits',
                    value: loading ? '—' : '${counts[1]}',
                    icon: Icons.style_outlined,
                    color: AppColors.secondary,
                  ),
                  statRowDivider(),
                  StatCell(
                    label: 'Portés',
                    value: loading ? '—' : '${counts[2]}',
                    icon: Icons.done_all_rounded,
                    color: AppColors.success,
                  ),
                  statRowDivider(),
                  StatCell(
                    label: 'Amis',
                    value: '${user.friends.length}',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            if (user.bestStreak > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Record : ${user.bestStreak} jours de suite',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Onglets en pastilles (3 onglets, pleine largeur — sans scroll ni chevron).
class _ProfileTabRail extends StatelessWidget {
  final TabController controller;
  final int pendingFriendRequests;

  static const entries = <
      ({
        IconData icon,
        String short,
      })>[
    (
      icon: Icons.photo_library_rounded,
      short: 'Souvenirs',
    ),
    (
      icon: Icons.people_alt_outlined,
      short: 'Amis',
    ),
    (
      icon: Icons.manage_accounts_rounded,
      short: 'Compte',
    ),
  ];

  const _ProfileTabRail({
    required this.controller,
    this.pendingFriendRequests = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          height: 44,
          child: Row(
            children: List.generate(entries.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 4,
                    right: i == entries.length - 1 ? 0 : 4,
                  ),
                  child: _ProfileTabPill(
                    icon: entries[i].icon,
                    label: entries[i].short,
                    selected: controller.index == i,
                    showBadge: i == 1 && pendingFriendRequests > 0,
                    badgeCount: pendingFriendRequests,
                    onTap: () => controller.animateTo(i),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _ProfileTabPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool showBadge;
  final int badgeCount;
  final VoidCallback onTap;

  const _ProfileTabPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.showBadge,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.divider.withValues(alpha: 0.85),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? AppColors.surface : AppColors.textSecondary,
                  ),
                  if (showBadge)
                    Positioned(
                      top: -5,
                      right: -9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.notificationBadge,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.surface : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        final maxWorn =
            garments.map((g) => g.timesWorn).reduce((a, b) => a > b ? a : b);
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

class _GalleryTab extends ConsumerWidget {
  final String uid;
  const _GalleryTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(outfitsProvider(uid));
    final garments = ref.watch(garmentsProvider(uid)).valueOrNull ?? [];
    final garmentCache = {for (final g in garments) g.id: g};
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
          return const AppEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'Aucun souvenir pour l\'instant',
            size: AppEmptyStateSize.compact,
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
            childAspectRatio: 1,
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
              onTap: () => OutfitDetailSheet.show(
                context,
                outfit: memory.outfit,
                garmentCache: garmentCache,
                mode: OutfitDetailMode.readOnly,
                focusPhotoUrl: memory.url,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          StorageAwareCachedImage(
                            imageUrl: memory.url,
                            fit: BoxFit.cover,
                            width: w,
                            height: h,
                            preferHighQuality: true,
                            loadingWidget: Container(
                              color: AppColors.surfaceVariant,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (_, __) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.graphite.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                date.isNotEmpty ? date : '-',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AsyncErrorState(
            onRetry: () => ref.invalidate(outfitsProvider(uid)),
          ),
    );
  }
}

class _AccountTab extends ConsumerWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const _AccountTab({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: _InfosTab(
        user: user,
        onLogout: onLogout,
      ),
    );
  }
}

class _FriendsTab extends ConsumerWidget {
  final UserModel user;

  const _FriendsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(receivedRequestsProvider);
    final friendsAsync = ref.watch(friendUsersProvider);

    final body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Demandes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.notificationBadge,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${requests.length}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...requests.map((req) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
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
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textHint),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                req.fromUsername,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle,
                                  color: AppColors.success),
                              iconSize: 28,
                              onPressed: () {
                                ref
                                    .read(friendshipNotifierProvider.notifier)
                                    .acceptRequest(req);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined,
                                  color: AppColors.textHint),
                              iconSize: 28,
                              onPressed: () {
                                ref
                                    .read(friendshipNotifierProvider.notifier)
                                    .rejectRequest(req);
                              },
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 6),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: ListTile(
              title: Text(context.l10n.styleSettingsTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StylePreferencesScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: SwitchListTile.adaptive(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              title: const Text(
                'Compte privé',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                user.isPrivate
                    ? 'Seuls tes amis voient ton contenu'
                    : 'Tout le monde peut voir ton contenu',
                style: AppTextStyles.caption,
              ),
              value: user.isPrivate,
              activeThumbColor: AppColors.accent,
              onChanged: (val) {
                ref
                    .read(friendshipNotifierProvider.notifier)
                    .togglePrivacy(val);
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Mes amis (${user.friends.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchUsersScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_outlined,
                    size: 20, color: AppColors.accent),
                tooltip: 'Ajouter un ami',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          friendsAsync.when(
            data: (friendUsers) {
              if (friendUsers.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.people_outline,
                  title: 'Aucun ami pour le moment',
                  size: AppEmptyStateSize.compact,
                );
              }
              return Column(
                children: friendUsers
                    .map((friend) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: UserListTile(
                    user: friend,
                    dense: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              UserProfileScreen(userId: friend.uid),
                        ),
                      );
                    },
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: AppColors.textHint),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'view') {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  UserProfileScreen(userId: friend.uid),
                            ),
                          );
                        } else if (value == 'remove') {
                          _confirmRemoveFriend(context, ref, friend);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 18, color: AppColors.textSecondary),
                              SizedBox(width: 10),
                              Text('Voir le profil'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.person_remove,
                                  size: 18, color: AppColors.error),
                              SizedBox(width: 10),
                              Text('Retirer',
                                  style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
                    .toList(),
              );
            },
            loading: () => _FriendsListSkeleton(count: user.friends.length),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Impossible de charger tes amis.',
                style: AppTextStyles.bodySecondary,
              ),
            ),
          ),
        ],
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          const SizedBox(height: 20),
          _MostWornChart(uid: user.uid),
        ],
      ),
    );
  }
}

void _confirmRemoveFriend(
  BuildContext context,
  WidgetRef ref,
  UserModel friend,
) {
  showDialog<void>(
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
            ref.invalidate(friendUsersProvider);
          },
          child: const Text('Retirer', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
}

/// Placeholders pendant le chargement Firestore des amis.
class _FriendsListSkeleton extends StatelessWidget {
  final int count;

  const _FriendsListSkeleton({required this.count});

  @override
  Widget build(BuildContext context) {
    final n = count.clamp(1, 5);
    return Column(
      children: List.generate(n, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.65)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 100 + (i * 12).toDouble(),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 72,
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _InfosTab extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const _InfosTab({
    required this.user,
    required this.onLogout,
  });

  @override
  ConsumerState<_InfosTab> createState() => _InfosTabState();
}

class _InfosTabState extends ConsumerState<_InfosTab> {
  bool _deletingAccount = false;
  bool _premiumApplying = false;
  final TextEditingController _premiumCodeController = TextEditingController();

  @override
  void dispose() {
    _premiumCodeController.dispose();
    super.dispose();
  }

  Future<void> _applyPremiumCode() async {
    final code = _premiumCodeController.text.trim();
    if (!isPremiumUnlockCodeValid(code)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code incorrect.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return;
    }

    setState(() => _premiumApplying = true);
    try {
      await ref.read(firestoreServiceProvider).updateUser(widget.user.uid, {
        'account_tier': 'premium',
      });
      if (!mounted) return;
      _premiumCodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: AppColors.white, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'UniSaps+ activé ! Profite des fonctionnalités IA.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } finally {
      if (mounted) setState(() => _premiumApplying = false);
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();
    bool obscure = true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 24),
              SizedBox(width: 10),
              Text('Supprimer le compte'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cette action est irréversible. Toutes tes données seront supprimées définitivement.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirme avec ton mot de passe :',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: AppColors.textHint),
                    onPressed: () => setStateDlg(() => obscure = !obscure),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Supprimer définitivement'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final password = passwordController.text.trim();
    if (password.isEmpty) return;

    setState(() => _deletingAccount = true);
    try {
      await ref.read(authNotifierProvider.notifier).deleteAccount(
            uid: widget.user.uid,
            password: password,
          );
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      String msg = 'Erreur lors de la suppression.';
      if (e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        msg = 'Mot de passe incorrect.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  Future<void> _showPremiumCodeDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Activer UniSaps+', style: AppTextStyles.heading3),
        content: TextField(
          controller: _premiumCodeController,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Code d’activation',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _premiumApplying
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await _applyPremiumCode();
                  },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberSince = widget.user.createdAt.isNotEmpty
        ? widget.user.createdAt.substring(0, 10)
        : '—';
    final email = widget.user.email;
    final emailShort =
        email.length > 22 ? '${email.substring(0, 20)}…' : email;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _AccountInfoTile(
                icon: Icons.alternate_email_rounded,
                iconColor: AppColors.primary,
                label: 'Pseudo',
                value: '@${widget.user.username}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AccountInfoTile(
                icon: Icons.mail_outline_rounded,
                iconColor: AppColors.accent,
                label: 'Email',
                value: emailShort,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AccountInfoTile(
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.textSecondary,
                label: 'Membre',
                value: memberSince,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AccountInfoTile(
                icon: Icons.workspace_premium_outlined,
                iconColor: widget.user.isPremium
                    ? AppColors.accent
                    : AppColors.textHint,
                label: 'UniSaps+',
                value: widget.user.isPremium ? 'Actif' : 'Gratuit',
                valueColor:
                    widget.user.isPremium ? AppColors.accent : null,
                highlight: widget.user.isPremium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const LanguageLocaleAccountTile(),
        if (!widget.user.isPremium) ...[
          const SizedBox(height: 8),
          Material(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _premiumApplying ? null : _showPremiumCodeDialog,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key_outlined,
                        size: 18, color: AppColors.accent.withValues(alpha: 0.95)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Activer UniSaps+ avec un code',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_premiumApplying)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.accent.withValues(alpha: 0.8)),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: OutlinedButton.icon(
                onPressed: widget.onLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.9)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 17),
                label: const Text(
                  'Déconnexion',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextButton.icon(
                onPressed:
                    _deletingAccount ? null : _showDeleteAccountDialog,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: _deletingAccount
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Icon(Icons.delete_outline_rounded, size: 17),
                label: const Text(
                  'Supprimer',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountInfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool highlight;

  const _AccountInfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppColors.accent.withValues(alpha: 0.35)
              : AppColors.divider.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
