import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../inspiration/inspiration_screen.dart';
import '../outfits/outfits_screen.dart';
import '../creations/creation_screen.dart';
import '../dressing/dressing_screen.dart';
import '../profile/profile_screen.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    final screens = [
      const InspirationScreen(),
      const OutfitsScreen(),
      const CreationScreen(),
      const DressingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
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
                ),
              ],
            ),
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
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
