import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garment_provider.dart';
import '../../providers/outfit_provider.dart';
import '../inspiration/inspiration_screen.dart';
import '../outfits/outfits_screen.dart';
import '../creations/creation_screen.dart';
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
  bool _tutorialStarted = false;

  static const _lockMessages = [
    '',
    'Ajoute un vêtement à ton dressing pour débloquer cette section',
    'Crée ton premier outfit pour débloquer cette section',
    'Crée ton premier outfit pour débloquer cette section',
  ];

  @override
  Widget build(BuildContext context) {
    final rawTab = ref.watch(selectedTabProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final uid = user?.uid ?? '';
    final tutorialStep = ref.watch(tutorialStepProvider);

    final garmentsAsync =
        uid.isNotEmpty ? ref.watch(garmentsProvider(uid)) : null;
    final outfitsAsync =
        uid.isNotEmpty ? ref.watch(outfitsProvider(uid)) : null;
    final hasGarments = garmentsAsync?.valueOrNull?.isNotEmpty ?? false;
    final hasOutfits = outfitsAsync?.valueOrNull?.isNotEmpty ?? false;

    if (user != null && !_tutorialStarted) {
      final t = user.tutorialSeen;
      final isNew = user.isNewUser ||
          !(t.dressing || t.creations || t.outfits || t.inspiration);
      if (isNew) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(tutorialStepProvider.notifier).state = 0;
        });
        _tutorialStarted = true;
      }
    }

    // Tabs: 0=Dressing, 1=Créer, 2=Outfits, 3=Inspo
    final tab = tutorialStep != null
        ? switch (tutorialStep) {
            0 => 0,
            1 => 1,
            2 => 2,
            _ => rawTab,
          }
        : rawTab;

    final screens = [
      const DressingScreen(),
      const CreationScreen(),
      const OutfitsScreen(),
      const InspirationScreen(),
    ];

    final tabUnlocked = [true, hasGarments, hasOutfits, hasOutfits];

    void onTabTap(int index) {
      if (tabUnlocked[index]) {
        ref.read(selectedTabProvider.notifier).state = index;
      } else {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _lockMessages[index],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary.withOpacity(0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    }

    final scaffold = Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: tab, children: screens),
          if (user != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: _ProfileAvatarButton(user: user),
            ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: tab,
        unlocked: tabUnlocked,
        onTap: onTabTap,
      ),
    );

    return Stack(
      children: [
        scaffold,
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
// Profile avatar button (top-right)
// ---------------------------------------------------------------------------
class _ProfileAvatarButton extends StatelessWidget {
  final UserModel user;
  const _ProfileAvatarButton({required this.user});

  @override
  Widget build(BuildContext context) {
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
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
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
          radius: 19,
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
                    fontSize: 15,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav bar (4 tabs, lock support)
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
    (Icons.add_circle_outline, Icons.add_circle, 'Créer'),
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(selected ? 8 : 0),
                  decoration: selected
                      ? BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      selected ? activeIcon : icon,
                      key: ValueKey('$selected$locked'),
                      color: color,
                      size: selected ? 26 : 24,
                    ),
                  ),
                ),
                if (locked)
                  Positioned(
                    right: -4,
                    top: -4,
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
                      child: Icon(
                        Icons.lock,
                        size: 10,
                        color: AppColors.textHint.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
// Tutorial overlay (3 steps: Dressing → Créer → Outfits)
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
        icon = Icons.brush;
        title = 'Crée ton outfit';
        description = 'Assemble tes vêtements en un look complet.';
        break;
      case 2:
      default:
        icon = Icons.local_fire_department;
        title = 'Choisis l\'outfit du jour';
        description = 'Sélectionne ton look du jour pour garder la flamme.';
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
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.15),
                        AppColors.accentLight.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 34),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        width: i == step ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == step
                              ? AppColors.accent
                              : AppColors.textHint.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onSkip,
                        child: const Text(
                          'Passer',
                          style: TextStyle(
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
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          step == 2 ? 'C\'est parti !' : 'Suivant',
                          style: const TextStyle(
                            color: Colors.white,
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
    );
  }
}
