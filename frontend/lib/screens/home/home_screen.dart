import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friendship_provider.dart';
import '../inspiration/inspiration_screen.dart';
import '../outfits/outfits_screen.dart';
import '../creations/creation_screen.dart';
import '../dressing/dressing_screen.dart';
import '../profile/profile_screen.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Étape actuelle du tutoriel global.
/// null = pas de tutoriel en cours.
final tutorialStepProvider = StateProvider<int?>((ref) => null);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _tutorialStarted = false;

  @override
  Widget build(BuildContext context) {
    final rawTab = ref.watch(selectedTabProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final tutorialStep = ref.watch(tutorialStepProvider);

    // Démarrer le tutoriel pour les nouveaux utilisateurs (une seule fois)
    if (user != null && !_tutorialStarted) {
      final t = user.tutorialSeen;
      final isNew = user.isNewUser ||
          !(t.dressing || t.creations || t.outfits || t.inspiration || t.profile);
      if (isNew) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(tutorialStepProvider.notifier).state = 0;
        });
        _tutorialStarted = true;
      }
    }

    // Onglet effectif affiché (piloté par le tutoriel si actif)
    final tab = tutorialStep != null
        ? switch (tutorialStep) {
            0 => 3, // Dressing
            1 => 2, // Créations
            2 => 1, // Outfits
            3 => 0, // Inspo
            _ => rawTab,
          }
        : rawTab;

    final screens = [
      const InspirationScreen(),
      const OutfitsScreen(),
      const CreationScreen(),
      const DressingScreen(),
      const ProfileScreen(),
    ];

    final scaffold = Scaffold(
      body: IndexedStack(
        index: tab,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: 'Inspo',
                  selected: tab == 0,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
                ),
                _NavItem(
                  icon: Icons.style_outlined,
                  activeIcon: Icons.style,
                  label: 'Outfits',
                  selected: tab == 1,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
                ),
                _NavItem(
                  icon: Icons.add_circle_outline,
                  activeIcon: Icons.add_circle,
                  label: 'Creer',
                  selected: tab == 2,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
                ),
                _NavItem(
                  icon: Icons.checkroom_outlined,
                  activeIcon: Icons.checkroom,
                  label: 'Dressing',
                  selected: tab == 3,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                  selected: tab == 4,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 4,
                  badge: ref.watch(receivedRequestsCountProvider),
                ),
              ],
            ),
          ),
        ),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
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
                      key: ValueKey(selected),
                      color: selected ? AppColors.accent : AppColors.textHint,
                      size: selected ? 26 : 24,
                    ),
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.accent : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    IconData icon;
    String title;
    String description;

    switch (step) {
      case 0:
        icon = Icons.checkroom;
        title = 'Commence par ton dressing';
        description = 'Ajoute un vetement pour remplir ton dressing.';
        break;
      case 1:
        icon = Icons.brush;
        title = 'Cree ton outfit';
        description = 'Assemble tes vetements en un look complet.';
        break;
      case 2:
        icon = Icons.local_fire_department;
        title = 'Choisis l\'outfit du jour';
        description = 'Selectionne ton look du jour pour garder la flamme.';
        break;
      case 3:
      default:
        icon = Icons.camera_alt_outlined;
        title = 'Partage ton outfit du jour';
        description = 'Poste la photo de ton look du jour.';
        break;
    }

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          color: Colors.black.withOpacity(0.55),
          child: Center(
            child: Container(
              width: size.width * 0.82,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.accent, size: 32),
                  ),
                  const SizedBox(height: 16),
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            step == 3 ? 'Terminer' : 'Suivant',
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
      ),
    );
  }
}
