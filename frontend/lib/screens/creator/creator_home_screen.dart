import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/nav_profile_bubble.dart';
import '../../l10n/l10n_context.dart';
import 'creator_dressing_screen.dart';
import 'creator_posts_screen.dart';
import 'creator_profile_screen.dart';

final creatorTabProvider = StateProvider<int>((ref) => 0);

class CreatorHomeScreen extends ConsumerStatefulWidget {
  const CreatorHomeScreen({super.key});

  @override
  ConsumerState<CreatorHomeScreen> createState() => _CreatorHomeScreenState();
}

class _CreatorHomeScreenState extends ConsumerState<CreatorHomeScreen> {
  late final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    ref.read(creatorTabProvider.notifier).state = index;
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tab = ref.watch(creatorTabProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => ref.read(creatorTabProvider.notifier).state = i,
        children: const [
          CreatorDressingScreen(),
          CreatorPostsScreen(),
          CreatorProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.graphite.withValues(alpha: 0.05),
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
                Expanded(
                  child: _CreatorNavItem(
                    icon: Icons.checkroom_outlined,
                    activeIcon: Icons.checkroom,
                    label: l10n.creatorTabGarments,
                    selected: tab == 0,
                    onTap: () => _goTo(0),
                  ),
                ),
                Expanded(
                  child: _CreatorNavItem(
                    icon: Icons.campaign_outlined,
                    activeIcon: Icons.campaign,
                    label: l10n.creatorTabPosts,
                    selected: tab == 1,
                    onTap: () => _goTo(1),
                  ),
                ),
                Expanded(
                  child: NavProfileBubble(
                    selected: tab == 2,
                    locked: false,
                    badgeCount: 0,
                    photoUrl: user?.displayAvatarUrl ?? '',
                    username: user?.username ?? '',
                    fallbackIcon: Icons.storefront,
                    onTap: () => _goTo(2),
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

class _CreatorNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CreatorNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textHint;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selected ? activeIcon : icon, size: 24, color: color),
          const SizedBox(height: 4),
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
    );
  }
}
