import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final tab = ref.watch(creatorTabProvider);

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Vêtements',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
