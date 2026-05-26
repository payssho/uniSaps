import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radii.dart';
import '../models/garment_model.dart';
import '../models/outfit_model.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import 'storage_aware_cached_image.dart';

/// Indique en bas de la photo qu’il y a des pièces à voir plus bas.
class PostGarmentScrollHint extends StatelessWidget {
  final int itemCount;
  final VoidCallback? onTap;

  const PostGarmentScrollHint({
    super.key,
    required this.itemCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = itemCount == 1 ? '1 pièce' : '$itemCount pièces';
    final pill = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.accent.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 4),
            Text(
              'Voir les $label',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: onTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: pill,
                ),
              )
            : pill,
      ),
    );
  }
}

/// Bandeau pièces avec résolution des photos via outfit Firestore si besoin.
class PostGarmentRefsForPost extends ConsumerWidget {
  final PostModel post;
  final int maxVisible;
  final VoidCallback? onViewAll;
  final bool compact;
  /// Dressing déjà chargé (profil) : enrichissement instantané, sans Firestore.
  final List<GarmentModel>? ownerGarments;
  final List<OutfitModel>? ownerOutfits;

  const PostGarmentRefsForPost({
    super.key,
    required this.post,
    this.maxVisible = 5,
    this.onViewAll,
    this.compact = false,
    this.ownerGarments,
    this.ownerOutfits,
  });

  List<GarmentRef> _resolvedRefs() {
    final garments = garmentsForPostEnrichment(
      post,
      ownerGarments ?? const [],
      ownerOutfits: ownerOutfits ?? const [],
    );
    return enrichGarmentRefs(post: post, garments: garments);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ownerGarments != null) {
      return PostGarmentRefsStrip(
        refs: _resolvedRefs(),
        maxVisible: maxVisible,
        onViewAll: onViewAll,
        compact: compact,
      );
    }

    final refsAsync = ref.watch(enrichedGarmentRefsProvider(post));
    return refsAsync.when(
      data: (refs) => PostGarmentRefsStrip(
        refs: refs,
        maxVisible: maxVisible,
        onViewAll: onViewAll,
        compact: compact,
      ),
      loading: () => PostGarmentRefsStrip(
        refs: post.garmentRefs,
        maxVisible: maxVisible,
        onViewAll: onViewAll,
        compact: compact,
      ),
      error: (_, __) => PostGarmentRefsStrip(
        refs: post.garmentRefs,
        maxVisible: maxVisible,
        onViewAll: onViewAll,
        compact: compact,
      ),
    );
  }
}

/// Liste détail avec photos enrichies.
class PostGarmentRefsDetailForPost extends ConsumerWidget {
  final PostModel post;
  final List<GarmentModel>? ownerGarments;
  final List<OutfitModel>? ownerOutfits;

  const PostGarmentRefsDetailForPost({
    super.key,
    required this.post,
    this.ownerGarments,
    this.ownerOutfits,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ownerGarments != null) {
      final garments = garmentsForPostEnrichment(
        post,
        ownerGarments!,
        ownerOutfits: ownerOutfits ?? const [],
      );
      final refs = enrichGarmentRefs(post: post, garments: garments);
      return PostGarmentRefsDetailList(refs: refs);
    }

    final refsAsync = ref.watch(enrichedGarmentRefsProvider(post));
    return refsAsync.when(
      data: (refs) => PostGarmentRefsDetailList(refs: refs),
      loading: () => PostGarmentRefsDetailList(refs: post.garmentRefs),
      error: (_, __) => PostGarmentRefsDetailList(refs: post.garmentRefs),
    );
  }
}

/// Affichage visuel des pièces référencées sur un post (nom + marque).
class PostGarmentRefsStrip extends StatelessWidget {
  final List<GarmentRef> refs;
  final int maxVisible;
  final VoidCallback? onViewAll;
  final bool compact;

  const PostGarmentRefsStrip({
    super.key,
    required this.refs,
    this.maxVisible = 5,
    this.onViewAll,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (refs.isEmpty) return const SizedBox.shrink();

    if (compact) {
      return _CompactAvatarRow(
        refs: refs,
        maxVisible: maxVisible,
        onViewAll: onViewAll,
      );
    }

    final overflow = refs.length > maxVisible;
    final visible = overflow ? refs.take(maxVisible).toList() : refs;

    const thumbSize = 72.0;
    return SizedBox(
      height: thumbSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length + (overflow ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (overflow && i == visible.length) {
            return _OverflowTile(
              count: refs.length - maxVisible,
              onTap: onViewAll,
              size: thumbSize,
            );
          }
          return _CompactGarmentTile(
            ref: visible[i],
            onTap: onViewAll,
            size: thumbSize,
          );
        },
      ),
    );
  }
}

class _CompactAvatarRow extends StatelessWidget {
  final List<GarmentRef> refs;
  final int maxVisible;
  final VoidCallback? onViewAll;

  const _CompactAvatarRow({
    required this.refs,
    required this.maxVisible,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final overflow = refs.length > maxVisible;
    final visible = overflow ? refs.take(maxVisible).toList() : refs;
    const size = 32.0;

    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: visible.length + (overflow ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          if (overflow && i == visible.length) {
            return GestureDetector(
              onTap: onViewAll,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '+${refs.length - maxVisible}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
            );
          }
          return PostGarmentRefAvatar(ref: visible[i], size: size);
        },
      ),
    );
  }
}

/// Liste verticale pour la sheet détail d'un post.
class PostGarmentRefsDetailList extends StatelessWidget {
  final List<GarmentRef> refs;

  const PostGarmentRefsDetailList({super.key, required this.refs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < refs.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _DetailGarmentCard(ref: refs[i], index: i + 1),
        ],
      ],
    );
  }
}

class _CompactGarmentTile extends StatelessWidget {
  final GarmentRef ref;
  final VoidCallback? onTap;
  final double size;

  const _CompactGarmentTile({
    required this.ref,
    this.onTap,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: PostGarmentRefAvatar(ref: ref, size: size),
      ),
    );
  }
}

class _OverflowTile extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final double size;

  const _OverflowTile({
    required this.count,
    this.onTap,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Text(
            '+$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailGarmentCard extends StatelessWidget {
  final GarmentRef ref;
  final int index;

  const _DetailGarmentCard({required this.ref, required this.index});

  @override
  Widget build(BuildContext context) {
    final brand = ref.brand.trim();
    final name = ref.name.trim();
    final title = name.isNotEmpty ? name : 'Pièce $index';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.scrimLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          PostGarmentRefAvatar(ref: ref, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (brand.isNotEmpty)
                  Text(
                    brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.accent.withValues(alpha: 0.95),
                    ),
                  ),
                if (brand.isNotEmpty) const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar coloré dérivé de la marque / nom (posts sans photo pièce).
class PostGarmentRefAvatar extends StatelessWidget {
  final GarmentRef ref;
  final double size;

  const PostGarmentRefAvatar({
    super.key,
    required this.ref,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _refGradientColors(ref);
    final initial = _refInitial(ref);
    final borderRadius = BorderRadius.circular(size >= 64 ? 14 : AppRadii.card);

    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: size * 0.55,
            color: AppColors.white.withValues(alpha: 0.12),
          ),
          Text(
            initial,
            style: TextStyle(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );

    if (ref.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size,
          height: size,
          child: StorageAwareCachedImage(
            imageUrl: ref.imageUrl,
            fit: BoxFit.cover,
            width: size,
            height: size,
              loadingWidget: Center(
                child: SizedBox(
                  width: size * 0.28,
                  height: size * 0.28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent.withValues(alpha: 0.7),
                  ),
                ),
              ),
            errorWidget: (_, __) => fallback,
          ),
        ),
      );
    }

    return fallback;
  }
}

String _refInitial(GarmentRef ref) {
  final source = ref.brand.trim().isNotEmpty
      ? ref.brand.trim()
      : ref.name.trim().isNotEmpty
          ? ref.name.trim()
          : '?';
  return source[0].toUpperCase();
}

List<Color> _refGradientColors(GarmentRef ref) {
  const palettes = <List<Color>>[
    [AppColors.accent, AppColors.primary],
    [AppColors.primary, Color(0xFF1E3A4F)],
    [Color(0xFF4A8F93), AppColors.accent],
    [Color(0xFF284B63), Color(0xFF3C6E71)],
    [Color(0xFF3C6E71), Color(0xFF353535)],
  ];
  final key = '${ref.brand}|${ref.name}'.hashCode.abs();
  return palettes[key % palettes.length];
}
