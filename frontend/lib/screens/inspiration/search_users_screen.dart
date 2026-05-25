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
import '../../l10n/l10n_context.dart';

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
  List<UserModel> _suggestions = [];
  bool _loading = false;
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    Future.microtask(_loadSuggestions);
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
      _loadSuggestions();
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

  Future<void> _loadSuggestions() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;
    setState(() => _loadingSuggestions = true);
    final users = await ref.read(friendshipNotifierProvider.notifier).suggestUsers(
          currentUid: currentUser.uid,
          currentFriends: currentUser.friends,
          limit: 12,
        );
    if (!mounted) return;
    setState(() {
      _suggestions = users;
      _loadingSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            decoration: InputDecoration(
              hintText: l10n.inspoSearchUser,
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
    final l10n = context.l10n;
    if (_controller.text.trim().isEmpty) {
      return _buildSuggestions(currentUser);
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_off_outlined, size: 64, color: AppColors.textHint.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text(l10n.searchNoResultsShort, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildSuggestions(currentUser, compactHeader: true)),
        ],
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

  Widget _buildSuggestions(UserModel? currentUser, {bool compactHeader = false}) {
    final l10n = context.l10n;
    if (_loadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: AppColors.textHint.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(l10n.searchTypePseudo, style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    final myFriends = currentUser?.friends ?? [];
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, compactHeader ? 0 : 12, 16, 12),
      itemCount: _suggestions.length + 1,
      separatorBuilder: (_, i) => i == 0 ? const SizedBox(height: 10) : const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                compactHeader
                    ? l10n.searchSuggestionsForYou
                    : l10n.searchFriendsSuggestions,
                style: AppTextStyles.heading3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.searchFriendsOfFriends,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          );
        }
        final user = _suggestions[i - 1];
        final mutualCount = user.friends.where((id) => myFriends.contains(id)).length;
        return _UserResultTile(
          user: user,
          currentUser: currentUser,
          subtitleOverride: mutualCount > 0
              ? '$mutualCount ${mutualCount > 1 ? l10n.searchMutualFriendsPlural : l10n.searchMutualFriendSingular}'
              : l10n.searchRandomSuggestion,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(userId: user.uid),
              ),
            );
          },
        );
      },
    );
  }
}

class _UserResultTile extends ConsumerWidget {
  final UserModel user;
  final UserModel? currentUser;
  final VoidCallback onTap;
  final String? subtitleOverride;

  const _UserResultTile({
    required this.user,
    required this.currentUser,
    required this.onTap,
    this.subtitleOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
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
                  if (subtitleOverride != null)
                    Text(
                      subtitleOverride!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                  if (!isFriend && mutualCount > 0)
                    Text(
                      '$mutualCount ${mutualCount > 1 ? l10n.searchMutualFriendsPlural : l10n.searchMutualFriendSingular}',
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
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      l10n.userProfileFriend,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
