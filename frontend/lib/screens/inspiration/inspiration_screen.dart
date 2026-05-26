import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/garment_model.dart';
import '../../models/outfit_model.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/inspiration_feed_dev_provider.dart';
import '../../data/mock_explore_feed_posts.dart';
import '../../providers/friendship_provider.dart';
import '../../providers/garment_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/post_view_tracker_provider.dart';
import '../../providers/widget_launch_provider.dart';
import '../home/home_screen.dart';
import 'search_users_screen.dart';
import 'user_profile_screen.dart';
import '../../widgets/premium_avatar_ring.dart';
import '../../widgets/async_error_state.dart';
import '../../widgets/loading_shimmer_grid.dart';
import '../../widgets/inspiration/empty_feed_message.dart';
import '../../widgets/storage_aware_cached_image.dart';
import '../../widgets/garment_category_glyph.dart';
import '../../widgets/post_garment_refs.dart';
import '../../widgets/post_detail_sheet.dart';

class InspirationScreen extends ConsumerStatefulWidget {
  const InspirationScreen({super.key});

  @override
  ConsumerState<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends ConsumerState<InspirationScreen> {
  final _horizontalPageController = PageController();
  bool _showFriends = true;
  bool _showScrollHint = false;
  bool _scrollHintChecked = false;

  @override
  void dispose() {
    _horizontalPageController.dispose();
    super.dispose();
  }

  void _checkScrollHint() {
    if (_scrollHintChecked) return;
    _scrollHintChecked = true;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final seen = user.tutorialSeen.inspiration;
    if (!seen) {
      setState(() => _showScrollHint = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _dismissScrollHint();
      });
    }
  }

  void _dismissScrollHint() {
    if (!_showScrollHint) return;
    setState(() => _showScrollHint = false);
    final uid = ref.read(authServiceProvider).uid;
    if (uid.isEmpty) return;
    ref.read(firestoreServiceProvider).updateUser(uid, {
      'tutorial_seen.inspiration': true,
    });
  }

  void _toggleFeed(bool friends) {
    if (_showFriends == friends) return;
    setState(() => _showFriends = friends);
    ref.read(inspirationExplorerVisibleProvider.notifier).state = !friends;
    _horizontalPageController.animateToPage(
      friends ? 0 : 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).uid;
    final user = ref.watch(currentUserProvider).valueOrNull;

    ref.listen(inspoPublishTriggerProvider, (prev, next) {
      if (next > (prev ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handlePublish(context);
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollHint());

    final hasPostedToday = ref.watch(hasPostedTodayProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Horizontal PageView: Amis / Explorer (swipeable)
          PageView(
            controller: _horizontalPageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (i) {
              setState(() => _showFriends = i == 0);
              ref.read(inspirationExplorerVisibleProvider.notifier).state =
                  i == 1;
            },
            children: [
              _FriendsFeed(
                uid: uid,
                user: user,
                onDoubleTap: (post) => _handleDoubleTapLike(post, uid),
                onScrollStart: _dismissScrollHint,
              ),
              _ExploreFeed(
                uid: uid,
                user: user,
                onDoubleTap: (post) => _handleDoubleTapLike(post, uid),
                onScrollStart: _dismissScrollHint,
              ),
            ],
          ),

          // Top overlay: toggle
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _FeedToggle(
                  showFriends: _showFriends,
                  onToggle: _toggleFeed,
                ),
              ],
            ),
          ),

          // Bouton Publier - masqué si déjà posté aujourd'hui
          if (!hasPostedToday)
            Positioned(
              bottom: 24,
              right: 16,
              child: _PublishButton(onTap: () => _handlePublish(context)),
            ),

          // Indication premier passage : défilement fluide (plus de mode « short »)
          if (_showScrollHint)
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: const Alignment(0, 0.25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.unfold_more_double_rounded,
                        color: AppColors.textSecondary.withValues(alpha: 0.75),
                        size: 40,
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(
                            begin: 0,
                            end: 10,
                            duration: 1100.ms,
                            curve: Curves.easeInOutCubic,
                          )
                          .shimmer(
                            duration: 1800.ms,
                            color: AppColors.accent.withValues(alpha: 0.35),
                          ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.scrimLight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.scrimMedium,
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Text(
                          'Fais défiler pour parcourir les looks',
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(alpha: 0.88),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleDoubleTapLike(PostModel post, String uid) {
    if (!post.isLikedBy(uid)) {
      ref.read(postNotifierProvider.notifier).toggleLike(post.id, uid);
    }
  }

  Future<void> _handlePublish(BuildContext context) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    if (user.dailyOutfitId.isEmpty) {
      ref.read(selectedTabProvider.notifier).state = 1;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('Choisis d\'abord ton outfit du jour'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accent.withOpacity(0.92),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      return;
    }

    final uid = ref.read(authServiceProvider).uid;
    try {
      final outfit = await ref
          .read(firestoreServiceProvider)
          .getOutfit(uid, user.dailyOutfitId);
      if (!mounted || !context.mounted) return;
      if (outfit == null) {
        ref.read(selectedTabProvider.notifier).state = 1;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                'Cet outfit n\'existe plus. Choisis un outfit du jour.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.accent.withOpacity(0.92),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          );
        return;
      }

      final postImageUrl = user.dailyPhotoUrl.isNotEmpty
          ? user.dailyPhotoUrl
          : outfit.referencePhotoUrl;

      if (postImageUrl.isEmpty) {
        ref.read(selectedTabProvider.notifier).state = 1;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                'Ajoute au moins une photo à ton outfit pour publier.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.accent.withOpacity(0.92),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          );
        return;
      }

      final garments = <GarmentModel>[];
      for (final gid in outfit.garmentIds) {
        final g =
            await ref.read(firestoreServiceProvider).getGarment(uid, gid);
        if (g != null) garments.add(g);
      }
      if (!mounted || !context.mounted) return;
      _showDailyPostSheet(
        context,
        user,
        outfit,
        garments,
        postImageUrl: postImageUrl,
      );
    } catch (_) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors de la préparation du post.')),
      );
    }
  }

  void _showDailyPostSheet(
    BuildContext context,
    UserModel user,
    OutfitModel outfit,
    List<GarmentModel> garments, {
    required String postImageUrl,
  }) {
    final captionController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.viewInsetsOf(ctx).bottom;
        final maxSheetH = MediaQuery.sizeOf(ctx).height * 0.92;
        final previewImageH =
            (MediaQuery.sizeOf(ctx).height * 0.34).clamp(180.0, 300.0);

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Publier l\'outfit du jour',
                                style: AppTextStyles.heading3,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.textSecondary),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: double.infinity,
                            height: previewImageH,
                            child: StorageAwareCachedImage(
                              imageUrl: postImageUrl,
                              fit: BoxFit.cover,
                              loadingWidget: Container(
                                color: AppColors.surfaceVariant,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textHint,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          outfit.name.isNotEmpty
                              ? outfit.name
                              : 'Mon outfit du jour',
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (garments.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Pièces du look',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 118,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: garments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (_, i) => _DailyPostGarmentTile(
                                garment: garments[i],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextField(
                          controller: captionController,
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Légende (optionnel)...',
                            filled: true,
                            fillColor: AppColors.surfaceVariant
                                .withValues(alpha: 0.45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.scrimLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final result = await ref
                              .read(postNotifierProvider.notifier)
                              .createPostFromDaily(
                                user: user,
                                outfit: outfit,
                                garments: garments,
                                caption: captionController.text.trim(),
                              );
                          if (!mounted) return;
                          if (result == 'ok') {
                            _toggleFeed(false);
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: AppColors.white, size: 18),
                                      SizedBox(width: 10),
                                      Text('Outfit publié !',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  margin: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 16),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                          } else if (result == 'already_posted') {
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: AppColors.white, size: 18),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Tu as déjà publié ton outfit aujourd\'hui !',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.warning,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  margin: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 16),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Erreur lors de la publication.')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Publier',
                          style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

/// Vignette pièce dans la preview de publication outfit du jour.
class _DailyPostGarmentTile extends StatelessWidget {
  final GarmentModel garment;

  const _DailyPostGarmentTile({required this.garment});

  @override
  Widget build(BuildContext context) {
    final label = [garment.brand, garment.name]
        .where((s) => s.isNotEmpty)
        .join('\n');

    return SizedBox(
      width: 76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 76,
              height: 76,
              child: garment.imageUrl.isNotEmpty
                  ? StorageAwareCachedImage(
                      imageUrl: garment.imageUrl,
                      fit: BoxFit.cover,
                      loadingWidget: Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __) => Container(
                        color: AppColors.surfaceVariant,
                        alignment: Alignment.center,
                        child: GarmentCategoryGlyph(
                          categoryKey: garment.category,
                          size: 28,
                          color: AppColors.textHint,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceVariant,
                      alignment: Alignment.center,
                      child: GarmentCategoryGlyph(
                        categoryKey: garment.category,
                        size: 28,
                        color: AppColors.textHint,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.isNotEmpty ? label : 'Pièce',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feed toggle (Amis / Explorer)
// ---------------------------------------------------------------------------
class _FeedToggle extends StatelessWidget {
  final bool showFriends;
  final ValueChanged<bool> onToggle;

  const _FeedToggle({required this.showFriends, required this.onToggle});

  static const _w = 232.0;

  @override
  Widget build(BuildContext context) {
    const pad = 4.0;
    const pillW = (_FeedToggle._w - pad * 3) / 2;
    return Semantics(
      label: 'Fil Inspiration : ${showFriends ? "Amis" : "Explorer"}',
      child: SizedBox(
      width: _FeedToggle._w,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.scrimLight),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.scrimLight,
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: showFriends ? pad : pad + pillW + pad,
            top: pad,
            width: pillW,
            bottom: pad,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onToggle(true),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: -0.2,
                          color: showFriends
                              ? AppColors.surface
                              : AppColors.textSecondary,
                        ),
                        child: const Text('Amis'),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onToggle(false),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: -0.2,
                          color: !showFriends
                              ? AppColors.surface
                              : AppColors.textSecondary,
                        ),
                        child: const Text('Explorer'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Publish button
// ---------------------------------------------------------------------------
class _PublishButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PublishButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Publier mon look du jour',
      button: true,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded,
                    color: AppColors.white.withValues(alpha: 0.95), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Publier',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.98),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.1,
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

// ---------------------------------------------------------------------------
// Friends feed
// ---------------------------------------------------------------------------
class _FriendsFeed extends ConsumerWidget {
  final String uid;
  final UserModel? user;
  final void Function(PostModel) onDoubleTap;
  final VoidCallback onScrollStart;

  const _FriendsFeed({
    required this.uid,
    required this.user,
    required this.onDoubleTap,
    required this.onScrollStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(friendsPostsProvider);

    return postsAsync.when(
      data: (posts) {
        if (user != null && user!.friends.isEmpty) {
          return EmptyFeedMessage(
            icon: Icons.people_outline,
            title: 'Aucun ami pour le moment',
            subtitle: 'Recherche des utilisateurs pour les ajouter !',
            action: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SearchUsersScreen()),
                );
              },
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Trouver des amis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        }

        // Ne garder que les posts du jour courant (même fuseau horaire local)
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));
        final todayPosts = posts.where((p) {
          final dt = DateTime.tryParse(p.createdAt)?.toLocal();
          if (dt == null) return false;
          return dt.isAfter(todayStart) && dt.isBefore(todayEnd);
        }).toList();

        // Mon post en premier
        todayPosts.sort((a, b) {
          if (a.userId == uid && b.userId != uid) return -1;
          if (b.userId == uid && a.userId != uid) return 1;
          return 0;
        });

        if (todayPosts.isEmpty) {
          return const EmptyFeedMessage(
            icon: Icons.article_outlined,
            title: 'Aucun post de tes amis aujourd\'hui',
            subtitle: 'Reviens demain ou invite tes amis à publier.',
          );
        }

        return _ContinuousFeed(
          posts: todayPosts,
          uid: uid,
          onDoubleTap: onDoubleTap,
          onScrollStart: onScrollStart,
        );
      },
      loading: () => const LoadingShimmerFeed(),
      error: (e, _) => AsyncErrorState(
            onRetry: () => ref.invalidate(friendsPostsProvider),
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Explore feed
// ---------------------------------------------------------------------------
class _ExploreFeed extends ConsumerWidget {
  final String uid;
  final UserModel? user;
  final void Function(PostModel) onDoubleTap;
  final VoidCallback onScrollStart;

  const _ExploreFeed({
    required this.uid,
    required this.user,
    required this.onDoubleTap,
    required this.onScrollStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(exploreFeedProvider);

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const EmptyFeedMessage(
            icon: Icons.explore_outlined,
            title: 'Aucun post à explorer',
            subtitle: 'Reviens plus tard pour découvrir de nouveaux looks.',
          );
        }
        return _ContinuousFeed(
          posts: posts,
          uid: uid,
          onDoubleTap: onDoubleTap,
          onScrollStart: onScrollStart,
        );
      },
      loading: () => const LoadingShimmerFeed(),
      error: (e, _) => AsyncErrorState(
            onRetry: () => ref.invalidate(exploreFeedProvider),
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fil vertical continu (scroll progressif, sans paging plein écran)
// ---------------------------------------------------------------------------

String _fmtPostClock(PostModel p) {
  final dt = DateTime.tryParse(p.createdAt)?.toLocal();
  if (dt == null) return '';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _ContinuousFeed extends ConsumerWidget {
  final List<PostModel> posts;
  final String uid;
  final void Function(PostModel) onDoubleTap;
  final VoidCallback onScrollStart;

  const _ContinuousFeed({
    required this.posts,
    required this.uid,
    required this.onDoubleTap,
    required this.onScrollStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top + 56;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 96;
    final myGarments = ref.watch(garmentsProvider(uid)).valueOrNull ?? [];
    final myOutfits = ref.watch(outfitsProvider(uid)).valueOrNull ?? [];

    return NotificationListener<ScrollStartNotification>(
      onNotification: (_) {
        onScrollStart();
        return false;
      },
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(12, topInset + 14, 12, bottomInset),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: posts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 22),
        itemBuilder: (context, index) {
          if (index == posts.length) return const _FeedEndFooter();

          final post = posts[index];
          final isOwn = post.userId == uid;
          if (post.isSponsored && post.id.isNotEmpty) {
            unawaited(ref.read(postViewTrackerProvider).registerView(post.id));
          }
          return _InspoPostCard(
            key: ValueKey<String>('explore_${index}_${post.id}'),
            post: post,
            uid: uid,
            ownerGarments: isOwn ? myGarments : null,
            ownerOutfits: isOwn ? myOutfits : null,
            onLike: () {
              ref
                  .read(postNotifierProvider.notifier)
                  .toggleLike(post.id, uid);
            },
            onDoubleTapLike: () => onDoubleTap(post),
            onUserTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: post.userId),
                ),
              );
            },
            onDelete: post.userId == uid
                ? () async {
                    final ok = await ref
                        .read(postNotifierProvider.notifier)
                        .deletePost(post.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Post supprimé.'
                                : 'Impossible de supprimer le post.',
                          ),
                          backgroundColor:
                              ok ? AppColors.success : AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                  }
                : null,
            onEditCaption: post.userId == uid
                ? (caption) => ref
                    .read(postNotifierProvider.notifier)
                    .updateCaption(post.id, caption)
                : null,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pied de fil (remplace l'ancienne slide plein écran)
// ---------------------------------------------------------------------------

class _FeedEndFooter extends StatelessWidget {
  const _FeedEndFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Material(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.scrimLight),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            children: [
              Icon(
                Icons.nights_stay_outlined,
                size: 38,
                color: AppColors.textHint.withValues(alpha: 0.8),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(
                    begin: 0.12,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 12),
              Text(
                'Fin des posts du jour',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3.copyWith(
                  letterSpacing: -0.35,
                  color: AppColors.textPrimary,
                ),
              ).animate(delay: 50.ms).fadeIn(duration: 420.ms),
              const SizedBox(height: 8),
              Text(
                'Reviens demain pour de nouveaux looks.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(
                  height: 1.35,
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
              ).animate(delay: 90.ms).fadeIn(duration: 420.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte feed : mise en page éditoriale + micro-interactions
// ---------------------------------------------------------------------------

class _InspoPostCard extends StatefulWidget {
  final PostModel post;
  final String uid;
  final List<GarmentModel>? ownerGarments;
  final List<OutfitModel>? ownerOutfits;
  final VoidCallback onLike;
  final VoidCallback onDoubleTapLike;
  final VoidCallback onUserTap;
  final VoidCallback? onDelete;
  final void Function(String caption)? onEditCaption;

  const _InspoPostCard({
    super.key,
    required this.post,
    required this.uid,
    this.ownerGarments,
    this.ownerOutfits,
    required this.onLike,
    required this.onDoubleTapLike,
    required this.onUserTap,
    this.onDelete,
    this.onEditCaption,
  });

  @override
  State<_InspoPostCard> createState() => _InspoPostCardState();
}

class _InspoPostCardState extends State<_InspoPostCard>
    with TickerProviderStateMixin {
  late bool _liked;
  late int _likes;

  late final AnimationController _likePulseCtl;
  late final Animation<double> _likePulseScale;
  late final AnimationController _menuRotCtl;

  bool _burst = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLikedBy(widget.uid);
    _likes = widget.post.likes;

    _likePulseCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _likePulseScale = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.16)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.16, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 60,
        ),
      ],
    ).animate(_likePulseCtl);

    _menuRotCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant _InspoPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likes != widget.post.likes ||
        oldWidget.uid != widget.uid) {
      _liked = widget.post.isLikedBy(widget.uid);
      _likes = widget.post.likes;
    }
  }

  @override
  void dispose() {
    _likePulseCtl.dispose();
    _menuRotCtl.dispose();
    super.dispose();
  }

  Future<void> _playLikeBurst() async {
    await _likePulseCtl.forward(from: 0);
    if (!mounted) return;
    await _likePulseCtl.reverse();
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
      if (_likes < 0) _likes = 0;
    });
    widget.onLike();
    unawaited(_playLikeBurst());
  }

  void _onDoubleTapImage() {
    if (!_liked) {
      setState(() {
        _liked = true;
        _likes += 1;
      });
      widget.onDoubleTapLike();
      unawaited(_playLikeBurst());
    }
    setState(() => _burst = true);
    Future.delayed(const Duration(milliseconds: 820), () {
      if (mounted) setState(() => _burst = false);
    });
  }

  void _showPostDetails(BuildContext context, PostModel post) {
    PostDetailSheet.show(
      context,
      post,
      ownerGarments: widget.ownerGarments,
      ownerOutfits: widget.ownerOutfits,
    );
  }

  Future<void> _showPostMenu() async {
    if (!mounted) return;
    await _menuRotCtl.forward(from: 0);
    if (!mounted) return;
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.graphite.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: MediaQuery.viewPaddingOf(ctx).bottom + 14,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Material(
              color: AppColors.surface.withValues(alpha: 0.92),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.3, 1),
                          duration: 340.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: const Icon(Icons.edit_outlined,
                          color: AppColors.accent),
                      title: const Text(
                        'Modifier la légende',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Texte visible sous la photo',
                        style: AppTextStyles.caption,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        if (!mounted || !context.mounted) return;
                        _showEditCaptionDialog(context);
                      },
                    )
                        .animate(delay: 40.ms)
                        .fadeIn(duration: 260.ms)
                        .slideY(
                          begin: 0.06,
                          duration: 300.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                      title: const Text(
                        'Supprimer le post',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Irréversible',
                        style: AppTextStyles.caption.copyWith(
                          color:
                              AppColors.error.withValues(alpha: 0.72),
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        if (!mounted || !context.mounted) return;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (d) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            title: const Text(
                              'Supprimer le post ?',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            content: const Text(
                              'Cette publication sera retirée du fil.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(d, false),
                                child: const Text('Annuler'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(d, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          widget.onDelete?.call();
                        }
                      },
                    )
                        .animate(delay: 90.ms)
                        .fadeIn(duration: 280.ms)
                        .slideY(
                          begin: 0.06,
                          duration: 320.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) await _menuRotCtl.reverse(from: _menuRotCtl.upperBound);
  }

  void _showEditCaptionDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.post.caption);
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Modifier la légende',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          minLines: 1,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Légende...',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(d);
              widget.onEditCaption?.call(controller.text.trim());
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ).then((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  Widget _burstOverlay() {
    if (!_burst) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.accent,
                AppColors.primary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Icon(
              Icons.favorite_rounded,
              size: 98,
              color: AppColors.white,
            )
                .animate()
                .scale(
                  begin: const Offset(0.12, 0.12),
                  end: const Offset(1.02, 1.02),
                  duration: 420.ms,
                  curve: Curves.easeOutCubic,
                )
                .then(delay: 40.ms)
                .fadeOut(
                  duration: 320.ms,
                  curve: Curves.easeOut,
                ),
          ),
        ),
      ),
    );
  }

  Widget _pulseLikeButton() {
    return ScaleTransition(
      scale: _likePulseScale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleLike,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Ink(
            width: 48,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: (_liked ? AppColors.accent : AppColors.surfaceVariant)
                  .withValues(alpha: _liked ? 0.2 : 0.55),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.elasticOut,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  key: ValueKey<bool>(_liked),
                  _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _liked ? AppColors.accent : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clock = _fmtPostClock(widget.post);

    return Material(
      elevation: 0,
      shadowColor: Colors.black26,
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.scrimLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 8),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onUserTap,
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: PremiumAvatarRing(
                        isPremium: widget.post.authorIsPremium,
                        padding: 3,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.surfaceVariant
                              .withValues(alpha: 0.95),
                          backgroundImage: widget.post.userPhotoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  widget.post.userPhotoUrl,
                                )
                              : null,
                          child: widget.post.userPhotoUrl.isEmpty
                              ? Text(
                                  widget.post.username.isNotEmpty
                                      ? widget.post.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textHint,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onUserTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${widget.post.username}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: -0.25,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (clock.isNotEmpty)
                              Text(
                                clock,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11.5,
                                  color:
                                      AppColors.textHint.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (!isDevMockExplorePostId(widget.post.id) &&
                                (widget.post.isSponsored ||
                                    widget.post.postKind == 'sponsored')) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.campaign_outlined,
                                    size: 12,
                                    color: AppColors.primary.withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sponsorisé',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary.withValues(alpha: 0.92),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.post.userId == widget.uid)
                  AnimatedBuilder(
                    animation: _menuRotCtl,
                    builder: (_, __) {
                      final t = Curves.easeOutCubic.transform(_menuRotCtl.value);
                      return Transform.rotate(
                        angle: t * -0.16,
                            child: IconButton(
                          tooltip: 'Options',
                          onPressed: () => unawaited(_showPostMenu()),
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.92),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.surfaceVariant.withValues(alpha: 0.85),
                          ),
                          splashRadius: 22,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: _onDoubleTapImage,
            child: AspectRatio(
              // Ratio plus « portrait » pour mieux voir les photos verticales.
              aspectRatio: 2 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.post.displayImageUrl.isNotEmpty
                      ? StorageAwareCachedImage(
                          imageUrl: widget.post.displayImageUrl,
                          fit: BoxFit.cover,
                          loadingWidget: Container(
                            color:
                                AppColors.surfaceVariant.withValues(alpha: 0.72),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      AppColors.accent.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __) => Container(
                            color: AppColors.surfaceVariant
                                .withValues(alpha: 0.75),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              size: 40,
                              color: AppColors.textHint,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.75),
                        ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.graphite.withValues(alpha: 0),
                            AppColors.graphite.withValues(alpha: 0.2),
                          ],
                          stops: const [0.0, 0.62, 1.0],
                        ),
                      ),
                    ),
                  ),
                  _burstOverlay(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _pulseLikeButton(),
                const SizedBox(width: 12),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.25,
                    color: _liked ? AppColors.accent : AppColors.textPrimary,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Text(
                      '$_likes',
                      key: ValueKey<int>(_likes),
                    ),
                  ),
                ),
                if (widget.post.garmentRefs.isNotEmpty) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        _showPostDetails(context, widget.post),
                    icon: const Icon(
                      Icons.checkroom_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    label: Text(
                      'Détails · ${widget.post.garmentRefs.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      backgroundColor:
                          AppColors.accent.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 14,
                right: 14,
                bottom: 14,
              ),
              child: Text(
                widget.post.caption,
                style: AppTextStyles.body.copyWith(height: 1.35),
              ),
            ),
          if (widget.post.garmentRefs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 14,
                right: 14,
                bottom: 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pièces du look',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PostGarmentRefsForPost(
                    post: widget.post,
                    onViewAll: () =>
                        _showPostDetails(context, widget.post),
                  ),
                ],
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.035,
          duration: 360.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ---------------------------------------------------------------------------
// Social sheet (Friend requests + Search merged)
// ---------------------------------------------------------------------------
class _SocialSheet extends ConsumerStatefulWidget {
  const _SocialSheet();

  @override
  ConsumerState<_SocialSheet> createState() => _SocialSheetState();
}

class _SocialSheetState extends ConsumerState<_SocialSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results =
          await ref.read(firestoreServiceProvider).searchUsers(query.trim());
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(receivedRequestsProvider);

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textHint,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Demandes'),
                    if ((requestsAsync.valueOrNull?.length ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${requestsAsync.valueOrNull?.length ?? 0}',
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Rechercher'),
            ],
          ),
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Friend requests
                _buildRequestsTab(requestsAsync),
                // Tab 2: Search
                _buildSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(AsyncValue<dynamic> requestsAsync) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text('Aucune demande en attente',
                  style: AppTextStyles.bodySecondary),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final req = requests[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.divider,
                    backgroundImage: req.fromPhotoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(req.fromPhotoUrl)
                        : null,
                    child: req.fromPhotoUrl.isEmpty
                        ? Text(
                            req.fromUsername.isNotEmpty
                                ? req.fromUsername[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textHint),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.fromUsername,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const Text('Veut être ton ami',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle,
                        color: AppColors.success, size: 28),
                    onPressed: () {
                      ref
                          .read(friendshipNotifierProvider.notifier)
                          .acceptRequest(req);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel,
                        color: AppColors.textHint, size: 28),
                    onPressed: () {
                      ref
                          .read(friendshipNotifierProvider.notifier)
                          .rejectRequest(req);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorState(
        onRetry: () => ref.invalidate(receivedRequestsProvider),
      ),
    );
  }

  Widget _buildSearchTab() {
    final uid = ref.read(authServiceProvider).uid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textHint),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onChanged: _search,
          ),
        ),
        if (_searching)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Tape un nom pour chercher'
                          : 'Aucun résultat',
                      style: AppTextStyles.bodySecondary,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    itemCount: _searchResults.length,
                    itemBuilder: (_, i) {
                      final u = _searchResults[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 4),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.surfaceVariant,
                          backgroundImage: u.profilePhotoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  u.profilePhotoUrl)
                              : null,
                          child: u.profilePhotoUrl.isEmpty
                              ? Text(
                                  u.username.isNotEmpty
                                      ? u.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHint),
                                )
                              : null,
                        ),
                        title: Text(u.username,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        trailing: u.uid == uid
                            ? const Chip(label: Text('Toi'))
                            : IconButton(
                                icon: const Icon(Icons.person_add_outlined,
                                    color: AppColors.accent),
                                onPressed: () {
                                  final me = ref.read(currentUserProvider).valueOrNull;
                                  if (me != null) {
                                    ref
                                        .read(friendshipNotifierProvider
                                            .notifier)
                                        .sendRequest(from: me, to: u);
                                  }
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Demande envoyée à ${u.username}'),
                                      behavior:
                                          SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  12)),
                                    ),
                                  );
                                },
                              ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserProfileScreen(userId: u.uid),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
