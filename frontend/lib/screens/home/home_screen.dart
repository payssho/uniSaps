import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
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

  /// Message affiché quand l’utilisateur tente d’ouvrir un onglet verrouillé.
  String _lockMessage(int index, bool hasGarments, bool hasOutfits) {
    switch (index) {
      case 1:
        return 'Ajoute un vêtement à ton dressing pour débloquer cette section';
      case 2:
        return 'Crée ton premier outfit pour débloquer cette section';
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

  void _showLockedTabSnackBar(
    int lockedIndex, {
    required bool hasGarments,
    required bool hasOutfits,
  }) {
    SnackBarAction? action;
    if (lockedIndex == 1) {
      action = SnackBarAction(
        label: 'Dressing',
        textColor: AppColors.white,
        onPressed: () => _goToTab(0),
      );
    } else if (lockedIndex == 2) {
      action = SnackBarAction(
        label: 'Outfits',
        textColor: AppColors.white,
        onPressed: () => _goToTab(1),
      );
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lockMessage(lockedIndex, hasGarments, hasOutfits),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary.withValues(alpha: 0.92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
          action: action,
        ),
      );
  }

  void _goToTab(int index) {
    if (index == _currentTab) return;
    // Si l'onglet cible n'est pas adjacent, on saute directement pour éviter
    // que les pages intermédiaires (ex. Inspo entre Outfits et Profil) flashent.
    final distance = (index - _currentTab).abs();
    if (distance > 1) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
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

    ref.listen(widgetLaunchRequestProvider, (prev, next) {
      if (next == null) return;
      if (next.outfitsSwipeMode) {
        ref.read(outfitsIsSwipeModeProvider.notifier).state = true;
      }
      final unlocked = [true, hasGarments, hasOutfits, true];
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
      final unlocked = [true, hasGarments, hasOutfits, true];
      if (unlocked[next]) {
        _goToTab(next);
      }
    });

    // Listen to tutorial changes
    ref.listen(tutorialStepProvider, (prev, next) {
      if (next != null) {
        final step = next.clamp(0, 3);
        _goToTab(step <= 2 ? step : 2);
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
    final tabUnlocked = [true, hasGarments, hasOutfits, true];

    void onTabTap(int index) {
      if (tabUnlocked[index]) {
        _goToTab(index);
      } else {
        _showLockedTabSnackBar(
          index,
          hasGarments: hasGarments,
          hasOutfits: hasOutfits,
        );
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
                onPageChanged: (index) {
                  if (index < tabUnlocked.length && !tabUnlocked[index]) {
                    // Onglet verrouillé - on rebondit vers la page courante
                    Future.microtask(() {
                      if (_pageController.hasClients) {
                        _pageController.animateToPage(
                          _currentTab,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                    _showLockedTabSnackBar(
                      index,
                      hasGarments: hasGarments,
                      hasOutfits: hasOutfits,
                    );
                  } else {
                    setState(() => _currentTab = index);
                    ref.read(selectedTabProvider.notifier).state = index;
                  }
                },
                children: const [
                  _KeepAlive(child: DressingScreen()),
                  _KeepAlive(child: OutfitsScreen()),
                  _KeepAlive(child: InspirationScreen()),
                  _KeepAlive(
                      child: ProfileScreen(embeddedInMainNav: true)),
                ],
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
            ],
          ),
          bottomNavigationBar: _BottomNavBar(
            currentIndex: _currentTab,
            unlocked: tabUnlocked,
            profileBadgeCount: requestCount,
            profilePhotoUrl: user?.profilePhotoUrl ?? '',
            profileUsername: user?.username ?? '',
            onTap: onTabTap,
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
    if (uid.isEmpty) return;
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
  final int currentIndex;
  final List<bool> unlocked;
  final int profileBadgeCount;

  /// Photo de profil pour la bulle du 4ᵉ onglet.
  final String profilePhotoUrl;
  final String profileUsername;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.unlocked,
    required this.profileBadgeCount,
    required this.profilePhotoUrl,
    required this.profileUsername,
    required this.onTap,
  });

  static const _tabs = [
    (Icons.checkroom_outlined, Icons.checkroom, 'Dressing'),
    (Icons.style_outlined, Icons.style, 'Outfits'),
    (Icons.explore_outlined, Icons.explore, 'Inspiration'),
  ];

  @override
  Widget build(BuildContext context) {
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
              ...List.generate(_tabs.length, (i) {
                final (icon, activeIcon, label) = _tabs[i];
                return Expanded(
                  child: _NavItem(
                    icon: icon,
                    activeIcon: activeIcon,
                    label: label,
                    selected: currentIndex == i,
                    locked: !unlocked[i],
                    requestBadgeCount: 0,
                    onTap: () => onTap(i),
                  ),
                );
              }),
              Expanded(
                child: NavProfileBubble(
                  selected: currentIndex == 3,
                  locked: !unlocked[3],
                  badgeCount: unlocked[3] ? profileBadgeCount : 0,
                  photoUrl: profilePhotoUrl,
                  username: profileUsername,
                  onTap: () => onTap(3),
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
// Tutorial overlay (4 steps: Dressing → Outfits → Inspo → Publier)
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
    final size = MediaQuery.of(context).size;

    final IconData icon;
    final String title;
    final String description;

    switch (step) {
      case 0:
        icon = Icons.checkroom;
        title = 'Commence par ton dressing';
        description = 'Ajoute un vêtement pour remplir ton dressing.';
        break;
      case 1:
        icon = Icons.style;
        title = 'Crée ton premier outfit';
        description = 'Assemble tes vêtements en un look complet.';
        break;
      case 2:
        icon = Icons.explore;
        title = 'Inspire-toi et publie';
        description = 'Découvre les looks des autres et partage le tien.';
        break;
      case 3:
      default:
        icon = Icons.camera_alt_outlined;
        title = 'Publie ton look du jour';
        description =
            'Depuis Inspiration, partage la photo de ton outfit du jour (1 par jour).';
        break;
    }

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          color: AppColors.graphite.withValues(alpha: 0.55),
          child: Center(
            child: Container(
              width: size.width * 0.82,
              constraints: BoxConstraints(maxHeight: size.height * 0.35),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.graphite.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withOpacity(0.15),
                          AppColors.accentLight.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.accent, size: 32),
                  ),
                  const SizedBox(height: 18),
                  Text(title,
                      style: AppTextStyles.heading2.copyWith(fontSize: 19),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(description,
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        width: i == step ? 18 : 8,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == step
                              ? AppColors.accent
                              : AppColors.textHint.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: onSkip,
                          child: const Text('Passer',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            step == 2 ? 'C\'est parti !' : 'Suivant',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600),
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
    );
  }
}
