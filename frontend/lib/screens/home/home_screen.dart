import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garment_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/friendship_provider.dart';
import '../inspiration/inspiration_screen.dart';
import '../inspiration/search_users_screen.dart';
import '../outfits/outfits_screen.dart';
import '../dressing/dressing_screen.dart';
import '../profile/profile_screen.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

final tutorialStepProvider = StateProvider<int?>((ref) => null);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  bool _tutorialStarted = false;
  int _currentTab = 0;

  static const _lockMessages = [
    '',
    'Ajoute un vêtement à ton dressing pour débloquer cette section',
    'Crée ton premier outfit pour débloquer cette section',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    if (index == _currentTab) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final uid = user?.uid ?? '';
    final tutorialStep = ref.watch(tutorialStepProvider);

    final garmentsAsync =
        uid.isNotEmpty ? ref.watch(garmentsProvider(uid)) : null;
    final outfitsAsync =
        uid.isNotEmpty ? ref.watch(outfitsProvider(uid)) : null;
    final hasGarments = garmentsAsync?.valueOrNull?.isNotEmpty ?? false;
    final hasOutfits = outfitsAsync?.valueOrNull?.isNotEmpty ?? false;

    // Listen to selectedTabProvider for programmatic tab changes (e.g. from InspirationScreen)
    ref.listen(selectedTabProvider, (prev, next) {
      if (next != _currentTab && next >= 0 && next < 3) {
        _goToTab(next);
      }
    });

    // Listen to tutorial changes
    ref.listen(tutorialStepProvider, (prev, next) {
      if (next != null) {
        final target = next.clamp(0, 2);
        _goToTab(target);
      }
    });

    if (user != null && !_tutorialStarted) {
      final t = user.tutorialSeen;
      final isNew = user.isNewUser ||
          !(t.dressing || t.outfits || t.inspiration);
      if (isNew) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(tutorialStepProvider.notifier).state = 0;
        });
        _tutorialStarted = true;
      }
    }

    // Tabs: 0=Dressing, 1=Outfits, 2=Inspo
    final tabUnlocked = [true, hasGarments, hasOutfits];

    void onTabTap(int index) {
      if (tabUnlocked[index]) {
        _goToTab(index);
      } else {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_lockMessages[index],
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary.withOpacity(0.92),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              duration: const Duration(seconds: 2),
            ),
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
                // Désactiver le swipe horizontal quand on est sur Outfits (onglet 1),
                // pour éviter les changements d'onglet accidentels en mode swipe.
                physics: _currentTab == 1
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentTab = index);
                  ref.read(selectedTabProvider.notifier).state = index;
                },
                children: [
                  _KeepAlive(child: const DressingScreen()),
                  _KeepAlive(child: const OutfitsScreen()),
                  _KeepAlive(child: const InspirationScreen()),
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
                        _SearchFriendsButton(),
                        const SizedBox(width: 10),
                      ],
                      _ProfileAvatarButton(user: user),
                    ],
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _BottomNavBar(
            currentIndex: _currentTab,
            unlocked: tabUnlocked,
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
    if (current >= 2) {
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
// Profile avatar button (top-right) + search friends (Inspo tab)
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
              color: Colors.black.withOpacity(0.15),
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

class _ProfileAvatarButton extends ConsumerWidget {
  final UserModel user;
  const _ProfileAvatarButton({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestCount = ref.watch(receivedRequestsCountProvider);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ProfileScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return SlideTransition(
                position: Tween(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage: user.profilePhotoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(user.profilePhotoUrl)
                  : null,
              child: user.profilePhotoUrl.isEmpty
                  ? Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
          ),
          if (requestCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$requestCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact bottom nav bar (3 tabs, lock support)
// ---------------------------------------------------------------------------
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<bool> unlocked;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.unlocked,
    required this.onTap,
  });

  static const _tabs = [
    (Icons.checkroom_outlined, Icons.checkroom, 'Dressing'),
    (Icons.style_outlined, Icons.style, 'Outfits'),
    (Icons.explore_outlined, Icons.explore, 'Inspo'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final (icon, activeIcon, label) = _tabs[i];
              return _NavItem(
                icon: icon,
                activeIcon: activeIcon,
                label: label,
                selected: currentIndex == i,
                locked: !unlocked[i],
                onTap: () => onTap(i),
              );
            }),
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked
        ? AppColors.textHint.withOpacity(0.35)
        : selected
            ? AppColors.accent
            : AppColors.textHint;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(selected ? 6 : 0),
                  decoration: selected
                      ? BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
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
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(Icons.lock, size: 9,
                          color: AppColors.textHint.withOpacity(0.6)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tutorial overlay (3 steps: Dressing → Outfits → Inspo)
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
      default:
        icon = Icons.explore;
        title = 'Inspire-toi et publie';
        description = 'Découvre les looks des autres et partage le tien.';
        break;
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: Container(
            width: size.width * 0.82,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
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
                              color: Colors.white,
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
    );
  }
}
