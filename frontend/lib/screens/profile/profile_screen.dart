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
import '../../providers/friendship_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/premium_avatar_ring.dart';
import '../inspiration/user_profile_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onProfileTabChanged);
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
      if (_tabController.index == 3) return;
      if (prev != null && prev > 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.animateTo(3);
      });
    });

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                      pendingFriendRequests: requestCount,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _ProfileTabRail(
                      controller: _tabController,
                      pendingRequests: requestCount,
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
                            controller: _tabController,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _StatsTab(uid: user.uid, user: user),
                              _OutfitsTab(uid: user.uid),
                              _GalleryTab(uid: user.uid),
                              _FriendsTab(user: user),
                              _InfosTab(
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

class _ProfileHero extends StatelessWidget {
  final UserModel user;
  final int pendingFriendRequests;
  /// Aligne le bloc avec les autres onglets (Sans bande retour + moins de marge haute).
  final bool embeddedInMainNav;

  const _ProfileHero({
    required this.user,
    required this.pendingFriendRequests,
    this.embeddedInMainNav = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        user.displayName.isNotEmpty ? user.displayName : user.username;
    final initials = user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : (displayName.isNotEmpty ? displayName[0].toUpperCase() : '?');
    final friendCount = user.friends.length;

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
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _HeroChip(
                                icon: Icons.local_fire_department_rounded,
                                label:
                                    '${user.currentStreak} j. série',
                                iconColor: AppColors.warning,
                              ),
                              _HeroChip(
                                icon: Icons.groups_rounded,
                                label:
                                    friendCount <= 1
                                        ? '$friendCount ami'
                                        : '$friendCount amis',
                                iconColor: AppColors.success,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (pendingFriendRequests > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pendingFriendRequests == 1
                                ? 'Une demande d’ami en attente'
                                : '$pendingFriendRequests demandes d’amis en attente',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.25,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$pendingFriendRequests',
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _HeroChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onglets en pastilles horizontales, synchronisés avec [TabController].
class _ProfileTabRail extends StatefulWidget {
  final TabController controller;
  final int pendingRequests;

  static const entries = <
      ({
        IconData icon,
        String short,
      })>[
    (
      icon: Icons.insights_rounded,
      short: 'Stats',
    ),
    (
      icon: Icons.checkroom_rounded,
      short: 'Tenues',
    ),
    (
      icon: Icons.photo_library_rounded,
      short: 'Souvenirs',
    ),
    (
      icon: Icons.group_rounded,
      short: 'Amis',
    ),
    (
      icon: Icons.manage_accounts_rounded,
      short: 'Infos',
    ),
  ];

  const _ProfileTabRail({
    required this.controller,
    required this.pendingRequests,
  });

  @override
  State<_ProfileTabRail> createState() => _ProfileTabRailState();
}

class _ProfileTabRailState extends State<_ProfileTabRail> {
  final ScrollController _hCtrl = ScrollController();
  bool _showRightFade = true;
  bool _showLeftFade = false;
  bool _userScrolled = false;

  @override
  void initState() {
    super.initState();
    _hCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _hCtrl.removeListener(_onScroll);
    _hCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hCtrl.hasClients) return;
    final pos = _hCtrl.position;
    final atEnd = pos.pixels >= pos.maxScrollExtent - 1;
    final atStart = pos.pixels <= 0;
    final showRight = !atEnd;
    final showLeft = !atStart;
    if (showRight != _showRightFade ||
        showLeft != _showLeftFade ||
        !_userScrolled) {
      setState(() {
        _showRightFade = showRight;
        _showLeftFade = showLeft;
        _userScrolled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        // Affiche le hint chevron tant que l’utilisateur n’a pas scrollé
        // et qu’il reste manifestement du contenu à droite.
        final showHintChevron = !_userScrolled && _showRightFade;
        return SizedBox(
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  // Couvre les cas où le listener du controller n’a pas
                  // encore tagué le rail (premier mouvement).
                  if (!_userScrolled) {
                    setState(() => _userScrolled = true);
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _hCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: List.generate(_ProfileTabRail.entries.length,
                        (i) => _buildEntry(context, i)),
                  ),
                ),
              ),
              // Fade gauche
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 22,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _showLeftFade ? 1 : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.background,
                            AppColors.background.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Fade droit + chevron hint
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 36,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _showRightFade ? 1 : 0,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.background.withValues(alpha: 0),
                                AppColors.background,
                              ],
                            ),
                          ),
                        ),
                        if (showHintChevron)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.9),
                            )
                                .animate(
                                  onPlay: (c) => c.repeat(reverse: true),
                                )
                                .moveX(
                                  begin: -2,
                                  end: 2,
                                  duration: 700.ms,
                                  curve: Curves.easeInOutCubic,
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
      },
    );
  }

  Widget _buildEntry(BuildContext context, int i) {
    const entries = _ProfileTabRail.entries;
    final controller = widget.controller;
    final pendingRequests = widget.pendingRequests;
    final e = entries[i];
    final selected = controller.index == i;
    final showBadge = i == 3 && pendingRequests > 0;

    return Padding(
      padding: EdgeInsets.only(
        left: i == 0 ? 0 : 6,
        right: i == entries.length - 1 ? 0 : 6,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.animateTo(i),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.divider.withValues(alpha: 0.9),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.scrimLight,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      e.icon,
                      size: 20,
                      color: selected
                          ? AppColors.surface
                          : AppColors.textSecondary,
                    ),
                    if (showBadge)
                      Positioned(
                        top: -4,
                        right: -12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.notificationBadge,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            pendingRequests > 99
                                ? '99+'
                                : '$pendingRequests',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  e.short,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: -0.2,
                    color: selected
                        ? AppColors.surface
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                      StatCard(
                          label: 'Vetements',
                          value: '${counts[0]}',
                          icon: Icons.checkroom),
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

Widget _outfitListThumbPlaceholder() {
  return Container(
    color: AppColors.surfaceVariant,
    alignment: Alignment.center,
    child: Icon(Icons.style_rounded,
        size: 26, color: AppColors.textHint.withOpacity(0.45)),
  );
}

class _OutfitsTab extends ConsumerWidget {
  final String uid;
  const _OutfitsTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(outfitsProvider(uid));
    return outfitsAsync.when(
      data: (outfits) {
        final sorted = [...outfits]
          ..sort((a, b) => b.timesWorn.compareTo(a.timesWorn));
        if (sorted.isEmpty) {
          return const Center(
              child: Text('Aucun outfit', style: AppTextStyles.bodySecondary));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final o = sorted[i];
            final thumbUrl = o.referencePhotoUrl.isNotEmpty
                ? o.referencePhotoUrl
                : (o.photoUrls.isNotEmpty ? o.photoUrls.first : '');
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
                      color: AppColors.graphite.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            o.name.isEmpty ? 'Outfit' : o.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (o.lastWorn.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('Dernier port : ${o.lastWorn}',
                                style: AppTextStyles.caption),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: thumbUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: thumbUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.surfaceVariant,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) =>
                                        _outfitListThumbPlaceholder(),
                                  )
                                : _outfitListThumbPlaceholder(),
                          ),
                        ),
                        if (o.timesWorn > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Porté ${o.timesWorn}×',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHint.withOpacity(0.95),
                            ),
                          ),
                        ],
                      ],
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
                Text('Dernier port : ${outfit.lastWorn}',
                    style: AppTextStyles.caption),
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
              if (outfit.referencePhotoUrl.isNotEmpty)
                const SizedBox(height: 16),
              FutureBuilder<List<GarmentModel>>(
                future:
                    ref.read(firestoreServiceProvider).mostWornGarments(uid),
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
                const Text('Aucun souvenir pour l\'instant',
                    style: AppTextStyles.bodySecondary),
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
              onTap: () =>
                  _showMemoryDetail(context, memory.url, memory.outfit, date),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
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
    final users = await ref
        .read(firestoreServiceProvider)
        .getUsersByIds(widget.user.friends);
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
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Demandes reçues',
                          style: AppTextStyles.heading3),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.notificationBadge,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${requests.length}',
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
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
                  const SizedBox(height: 8),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
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
                color: widget.user.isPrivate
                    ? AppColors.accent
                    : AppColors.textHint,
              ),
              value: widget.user.isPrivate,
              activeColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onChanged: (val) {
                ref
                    .read(friendshipNotifierProvider.notifier)
                    .togglePrivacy(val);
              },
            ),
          ),
          const SizedBox(height: 24),
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
                  Icon(Icons.people_outline,
                      size: 48, color: AppColors.textHint.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('Aucun ami pour le moment',
                      style: AppTextStyles.bodySecondary),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint),
                            )
                          : null,
                    ),
                    title: Text(
                      friend.username,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: friend.displayName.isNotEmpty
                        ? Text(friend.displayName, style: AppTextStyles.caption)
                        : null,
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: AppColors.textHint),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'view') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserProfileScreen(userId: friend.uid),
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
                              Icon(Icons.person_outline,
                                  size: 18, color: AppColors.textSecondary),
                              SizedBox(width: 10),
                              Text('Voir le profil'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
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
              ref
                  .read(friendshipNotifierProvider.notifier)
                  .removeFriend(friend.uid);
              setState(() {
                _friendUsers.removeWhere((u) => u.uid == friend.uid);
              });
            },
            child:
                const Text('Retirer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _InfosTab extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const _InfosTab({required this.user, required this.onLogout});

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _InfoRow(label: 'Email', value: widget.user.email),
          _InfoRow(label: 'Pseudo', value: widget.user.username),
          _InfoRow(label: 'Nom', value: widget.user.displayName),
          _InfoRow(
              label: 'Membre depuis',
              value: widget.user.createdAt.isNotEmpty
                  ? widget.user.createdAt.substring(0, 10)
                  : '-'),
          _InfoRow(
              label: 'Meilleur streak',
              value: '${widget.user.bestStreak} jours'),
          _InfoRow(label: 'Amis', value: '${widget.user.friends.length}'),
          _InfoRow(
              label: 'Compte',
              value: widget.user.isPrivate ? 'Prive' : 'Public'),
          _InfoRow(
            label: 'UniSaps+',
            value: widget.user.isPremium ? 'Actif' : 'Gratuit',
          ),
          if (!widget.user.isPremium) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Code d’activation',
                style: AppTextStyles.bodySecondary.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _premiumCodeController,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Entre ton code UniSaps+',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _premiumApplying ? null : _applyPremiumCode,
                child: _premiumApplying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.workspace_premium_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Activer UniSaps+',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textSecondary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: widget.onLogout,
              child: const Text('Se déconnecter',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _deletingAccount ? null : _showDeleteAccountDialog,
              child: _deletingAccount
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.error),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_forever_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Supprimer le compte',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cette action est irréversible.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
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
