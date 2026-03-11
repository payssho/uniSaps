import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friendship_provider.dart';
import 'user_profile_screen.dart';

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<UserModel> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      final myFriends = currentUser?.friends ?? [];

      final results = await ref
          .read(friendshipNotifierProvider.notifier)
          .searchUsers(trimmed);

      // Trier par nombre d'amis en commun (descendant)
      results.sort((a, b) {
        final mutualA =
            a.friends.where((id) => myFriends.contains(id)).length;
        final mutualB =
            b.friends.where((id) => myFriends.contains(id)).length;
        return mutualB.compareTo(mutualA);
      });

      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 15),
              prefixIcon: Icon(Icons.search, color: AppColors.textHint, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: _buildBody(currentUser),
    );
  }

  Widget _buildBody(UserModel? currentUser) {
    if (_controller.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: AppColors.textHint.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Tape un pseudo pour chercher', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: AppColors.textHint.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Aucun resultat', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _UserResultTile(
        user: _results[i],
        currentUser: currentUser,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: _results[i].uid),
            ),
          );
        },
      ),
    );
  }
}

class _UserResultTile extends ConsumerWidget {
  final UserModel user;
  final UserModel? currentUser;
  final VoidCallback onTap;

  const _UserResultTile({
    required this.user,
    required this.currentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFriend = currentUser?.friends.contains(user.uid) ?? false;
    final myFriends = currentUser?.friends ?? [];
    final mutualCount =
        user.friends.where((id) => myFriends.contains(id)).length;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage: user.profilePhotoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(user.profilePhotoUrl)
                  : null,
              child: user.profilePhotoUrl.isEmpty
                  ? Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.textHint,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  if (user.displayName.isNotEmpty)
                    Text(user.displayName, style: AppTextStyles.caption),
                  if (!isFriend && mutualCount > 0)
                    Text(
                      '$mutualCount ami${mutualCount > 1 ? 's' : ''} en commun',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (isFriend)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text('Ami', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else if (user.isPrivate)
              const Icon(Icons.lock_outline, size: 18, color: AppColors.textHint)
            else
              const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
