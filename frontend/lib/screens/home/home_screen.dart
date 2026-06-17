import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/style_home_layout.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garment_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/friendship_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/widget_launch_provider.dart';
import '../../providers/inspiration_feed_dev_provider.dart';
import '../inspiration/inspiration_screen.dart';
import '../inspiration/search_users_screen.dart';
import '../outfits/outfits_screen.dart';
import '../dressing/dressing_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/nav_profile_bubble.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n_context.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

final tutorialStepProvider = StateProvider<int?>((ref) => null);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  bool _tutorialStarted = false;
  int _currentTab = 0;
  List<int>? _lastSyncedTabOrder;

  /// Message affiché quand l’utilisateur tente d’ouvrir un onglet verrouillé.
  String _lockMessage(AppLocalizations l10n, int index) {
    switch (index) {
      case 1:
        return l10n.lockTabAddGarment;
      case 2:
        return l10n.lockTabCreateOutfit;
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force le refetch de la météo lors d'un retour de l'app au premier plan,
      // pour que la "météo du jour" soit toujours celle d'aujourd'hui.
      ref.invalidate(todayWeatherFetchProvider);
    }
  }

  void _showLockedTabSnackBar(int lockedIndex) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _lockMessage(l10n, lockedIndex),
            style: const TextStyle(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary.withValues(alpha: 0.92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _goToTab(int logicalIndex, List<int> tabOrder) {
    if (logicalIndex == _currentTab) return;
    final physical = homePhysicalIndexForLogical(tabOrder, logicalIndex);
    final currentPhysical =
        homePhysicalIndexForLogical(tabOrder, _currentTab);
    final distance = (physical - currentPhysical).abs();
    if (distance > 1) {
      _pageController.jumpToPage(physical);
    } else {
      _pageController.animateToPage(
        physical,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _syncPageToTabOrder(List<int> tabOrder) {
    if (_lastSyncedTabOrder != null &&
        listEquals(_lastSyncedTabOrder, tabOrder)) {
      return;
    }
    _lastSyncedTabOrder = List<int>.from(tabOrder);
    if (!_pageController.hasClients) return;
    final physical = homePhysicalIndexForLogical(tabOrder, _currentTab);
    final current = _pageController.page?.round() ?? 0;
    if (current != physical) {
      _pageController.jumpToPage(physical);
    }
  }

  static Widget _pageForLogicalTab(int logical) {
    switch (logical) {
      case 0:
        return const _KeepAlive(child: DressingScreen());
      case 1:
        return const _KeepAlive(child: OutfitsScreen());
      case 2:
        return const _KeepAlive(child: InspirationScreen());
      case 3:
      default:
        return const _KeepAlive(
          child: ProfileScreen(embeddedInMainNav: true),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isOutfitsSwipe =
        ref.watch(outfitsIsSwipeModeProvider); // true si mode Swipe
    final hasDailyOutfit = (user?.dailyOutfitId ?? '').isNotEmpty;
    final uid = user?.uid ?? '';
    final tutorialStep = ref.watch(tutorialStepProvider);

    final garmentsAsync =
        uid.isNotEmpty ? ref.watch(garmentsProvider(uid)) : null;
    final outfitsAsync =
        uid.isNotEmpty ? ref.watch(outfitsProvider(uid)) : null;
    final hasGarments = garmentsAsync?.valueOrNull?.isNotEmpty ?? false;
    final hasOutfits = outfitsAsync?.valueOrNull?.isNotEmpty ?? false;
    final tabOrder = homeTabLogicalOrder(
      user?.hasStyleProfile == true ? user?.styleProfile : null,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPageToTabOrder(tabOrder);
    });

    ref.listen(widgetLaunchRequestProvider, (prev, next) {
      if (next == null) return;
      if (next.outfitsSwipeMode) {
        ref.read(outfitsIsSwipeModeProvider.notifier).state = true;
      }
      final unlocked = tutorialStep != null
          ? const [true, true, true, true]
          : [true, hasGarments, hasOutfits, true];
      if (unlocked[next.tab]) {
        ref.read(selectedTabProvider.notifier).state = next.tab;
      }
      if (next.openPublish) {
        ref.read(inspoPublishTriggerProvider.notifier).state++;
      }
      ref.read(widgetLaunchRequestProvider.notifier).state = null;
    });

    // Listen to selectedTabProvider for programmatic tab changes (e.g. from InspirationScreen)
    ref.listen(selectedTabProvider, (prev, next) {
      if (next == _currentTab || next < 0 || next >= 4) return;
      final unlocked = tutorialStep != null
          ? const [true, true, true, true]
          : [true, hasGarments, hasOutfits, true];
      if (unlocked[next]) {
        _goToTab(next, tabOrder);
      }
    });

    // Listen to tutorial changes
    ref.listen(tutorialStepProvider, (prev, next) {
      if (next != null) {
        _goToTab(next.clamp(0, 3), tabOrder);
      }
    });

    if (user != null && !_tutorialStarted) {
      final t = user.tutorialSeen;
      final isNew =
          user.isNewUser || !(t.dressing || t.outfits || t.inspiration);
      if (isNew) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(tutorialStepProvider.notifier).state = 0;
        });
        _tutorialStarted = true;
      }
    }

    final requestCount = ref.watch(receivedRequestsCountProvider);

    // Tabs: 0=Dressing, 1=Outfits, 2=Inspo, 3=Profil (toujours déverrouillé)
    final tutorialActive = tutorialStep != null;
    final tabUnlocked = tutorialActive
        ? const [true, true, true, true]
        : [true, hasGarments, hasOutfits, true];

    void onTabTap(int index) {
      if (tabUnlocked[index]) {
        _goToTab(index, tabOrder);
      } else {
        _showLockedTabSnackBar(index);
      }
    }

    return Stack(
      children: [
        Scaffold(
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                physics: (_currentTab == 1 && isOutfitsSwipe && !hasDailyOutfit)
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (physicalIndex) {
                  final logicalIndex =
                      homeLogicalIndexForPhysical(tabOrder, physicalIndex);
                  if (!tabUnlocked[logicalIndex]) {
                    Future.microtask(() {
                      if (_pageController.hasClients) {
                        _pageController.animateToPage(
                          homePhysicalIndexForLogical(tabOrder, _currentTab),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                    _showLockedTabSnackBar(logicalIndex);
                  } else {
                    setState(() => _currentTab = logicalIndex);
                    ref.read(selectedTabProvider.notifier).state =
                        logicalIndex;
                  }
                },
                children: tabOrder
                    .map(_HomeScreenState._pageForLogicalTab)
                    .toList(),
              ),
              if (user != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_currentTab == 2) ...[
                        if (kDebugMode)
                          Consumer(
                            builder: (_, ref, __) {
                              final explorer =
                                  ref.watch(inspirationExplorerVisibleProvider);
                              if (!explorer) {
                                return const SizedBox.shrink();
                              }
                              return const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ExploreDevMockAdsToggle(),
                                  SizedBox(width: 8),
                                ],
                              );
                            },
                          ),
                        _SearchFriendsButton(),
                      ],
                    ],
                  ),
                ),
              if (tutorialStep != null && user != null)
                _TutorialOverlay(
                  step: tutorialStep,
                  user: user,
                  onNext: () => _handleNextTutorialStep(user),
                  onSkip: () => _finishTutorial(user),
                ),
            ],
          ),
          bottomNavigationBar: _BottomNavBar(
            tabOrder: tabOrder,
            currentLogicalIndex: _currentTab,
            unlocked: tabUnlocked,
            profileBadgeCount: requestCount,
            profilePhotoUrl: user?.profilePhotoUrl ?? '',
            profileUsername: user?.username ?? '',
            profileSpotlight: tutorialStep == 3,
            onTap: onTabTap,
          ),
        ),
      ],
    );
  }

  Future<void> _handleNextTutorialStep(UserModel user) async {
    final stepNotifier = ref.read(tutorialStepProvider.notifier);
    final current = stepNotifier.state ?? 0;
    if (current >= 3) {
      await _finishTutorial(user);
    } else {
      stepNotifier.state = current + 1;
    }
  }

  Future<void> _finishTutorial(UserModel user) async {
    ref.read(tutorialStepProvider.notifier).state = null;
    final uid = user.uid;
    if (uid.isNotEmpty) {
      await ref.read(firestoreServiceProvider).updateUser(uid, {
        'tutorial_seen': {
          'dressing': true,
          'creations': true,
          'outfits': true,
          'profile': true,
          'inspiration': true,
        },
        'is_new_user': false,
      });
    }
    _goToTab(0, homeTabLogicalOrder(user.styleProfile));
  }
}

// ---------------------------------------------------------------------------
// Keep alive wrapper for PageView children
// ---------------------------------------------------------------------------
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ---------------------------------------------------------------------------
// Faux posts sponsorisés — fil Explorer (dev / test)
// ---------------------------------------------------------------------------
class _ExploreDevMockAdsToggle extends ConsumerWidget {
  const _ExploreDevMockAdsToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(exploreDevMockPostsEnabledProvider);
    return Tooltip(
      message: on
          ? 'Désactiver les faux posts sponsorisés (test)'
          : 'Activer ~30 faux posts sponsorisés (test)',
      child: GestureDetector(
        onTap: () => ref
            .read(exploreDevMockPostsEnabledProvider.notifier)
            .update((s) => !s),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: on
                ? AppColors.accent.withValues(alpha: 0.2)
                : AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.graphite.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.campaign_outlined,
            size: 18,
            color: on ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search friends (Inspo tab — top-right overlay)
// ---------------------------------------------------------------------------
class _SearchFriendsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const SearchUsersScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 220),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.graphite.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.search,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact bottom nav bar (4 tabs, lock support)
// ---------------------------------------------------------------------------
class _BottomNavBar extends StatelessWidget {
  final List<int> tabOrder;
  final int currentLogicalIndex;
  final List<bool> unlocked;
  final int profileBadgeCount;

  /// Photo de profil pour la bulle du 4ᵉ onglet.
  final String profilePhotoUrl;
  final String profileUsername;
  final bool profileSpotlight;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.tabOrder,
    required this.currentLogicalIndex,
    required this.unlocked,
    required this.profileBadgeCount,
    required this.profilePhotoUrl,
    required this.profileUsername,
    this.profileSpotlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabLabels = [
      (Icons.checkroom_outlined, Icons.checkroom, l10n.navDressing),
      (Icons.style_outlined, Icons.style, l10n.navOutfits),
      (Icons.explore_outlined, Icons.explore, l10n.navInspiration),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              for (final logical in tabOrder)
                Expanded(
                  child: logical == 3
                      ? NavProfileBubble(
                          selected: currentLogicalIndex == 3,
                          locked: !unlocked[3],
                          badgeCount:
                              unlocked[3] ? profileBadgeCount : 0,
                          photoUrl: profilePhotoUrl,
                          username: profileUsername,
                          tutorialSpotlight: profileSpotlight,
                          onTap: () => onTap(3),
                        )
                      : _NavItem(
                          icon: tabLabels[logical].$1,
                          activeIcon: tabLabels[logical].$2,
                          label: tabLabels[logical].$3,
                          selected: currentLogicalIndex == logical,
                          locked: !unlocked[logical],
                          requestBadgeCount: 0,
                          onTap: () => onTap(logical),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final bool locked;

  /// Pastille type demandes d’amis (profil uniquement).
  final int requestBadgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.locked = false,
    this.requestBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked
        ? AppColors.textHint.withOpacity(0.35)
        : selected
            ? AppColors.accent
            : AppColors.textHint;

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      enabled: !locked,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(selected ? 6 : 0),
                decoration: selected
                    ? BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      )
                    : null,
                child: Icon(
                  selected ? activeIcon : icon,
                  color: color,
                  size: selected ? 22 : 20,
                ),
              ),
              if (locked)
                Positioned(
                  right: 4,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.graphite.withOpacity(0.08),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(Icons.lock,
                        size: 9, color: AppColors.textHint.withOpacity(0.6)),
                  ),
                ),
              if (!locked && requestBadgeCount > 0)
                Positioned(
                  right: 2,
                  top: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    child: Text(
                      requestBadgeCount > 99 ? '99+' : '$requestBadgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: label.length > 9 ? 9 : 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
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
// Tutorial overlay (4 steps: Dressing → Outfits → Inspo → Profil)
// ---------------------------------------------------------------------------
class _TutorialOverlay extends StatelessWidget {
  final int step;
  final UserModel user;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TutorialOverlay({
    required this.step,
    required this.user,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const navBarHeight = kBottomNavigationBarHeight;
    final maxCardHeight =
        (size.height - bottomInset - navBarHeight - 48).clamp(220.0, 420.0);

    final IconData icon;
    final String title;
    final String description;

    switch (step) {
      case 0:
        icon = Icons.checkroom;
        title = l10n.tutorialDressingTitle;
        description = l10n.tutorialDressingDesc;
        break;
      case 1:
        icon = Icons.style;
        title = l10n.tutorialOutfitsTitle;
        description = l10n.tutorialOutfitsDesc;
        break;
      case 2:
        icon = Icons.explore;
        title = l10n.tutorialInspoTitle;
        description = l10n.tutorialInspoDiscoverDesc;
        break;
      case 3:
      default:
        icon = Icons.person_outline_rounded;
        title = l10n.tutorialProfileTitle;
        description = l10n.tutorialProfileDesc;
        break;
    }

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          color: AppColors.graphite.withValues(alpha: 0.55),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, navBarHeight + bottomInset + 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.88,
                  maxHeight: maxCardHeight,
                ),
                child: Material(
                  color: AppColors.surface,
                  elevation: 8,
                  shadowColor: AppColors.graphite.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accent.withValues(alpha: 0.15),
                                AppColors.accentLight.withValues(alpha: 0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: AppColors.accent, size: 30),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          style: AppTextStyles.heading2.copyWith(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: AppTextStyles.bodySecondary.copyWith(
                            fontSize: 14,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            return Container(
                              width: i == step ? 18 : 8,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i == step
                                    ? AppColors.accent
                                    : AppColors.textHint.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: onSkip,
                                child: Text(
                                  l10n.commonSkip,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  step >= 3 ? l10n.tutorialGotIt : l10n.commonNext,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
