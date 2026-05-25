import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radii.dart';
import '../models/post_model.dart';

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

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length + (overflow ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (overflow && i == visible.length) {
            return _OverflowTile(
              count: refs.length - maxVisible,
              onTap: onViewAll,
            );
          }
          return _CompactGarmentTile(
            ref: visible[i],
            onTap: onViewAll,
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
    const size = 34.0;

    return SizedBox(
      height: size,
      child: Row(
        children: [
          for (var i = 0; i < visible.length; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
              child: PostGarmentRefAvatar(ref: visible[i], size: size),
            ),
          if (overflow) ...[
            const SizedBox(width: 6),
            GestureDetector(
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
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ],
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

  const _CompactGarmentTile({required this.ref, this.onTap});

  @override
  Widget build(BuildContext context) {
    final brand = ref.brand.trim();
    final name = ref.name.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: SizedBox(
          width: 76,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PostGarmentRefAvatar(ref: ref, size: 76),
              const SizedBox(height: 6),
              if (brand.isNotEmpty)
                Text(
                  brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (name.isNotEmpty)
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverflowTile extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _OverflowTile({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Voir tout',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
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
          Icon(
            Icons.checkroom_outlined,
            size: 20,
            color: AppColors.textHint.withValues(alpha: 0.7),
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size >= 64 ? 14 : AppRadii.card),
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
