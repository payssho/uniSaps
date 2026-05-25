import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/l10n_context.dart';

/// Mode d’affichage de l’écran Outfits (swipe ou bibliothèque).
enum OutfitsViewMode { swipe, biblio }

/// Segmented control Swipe / Biblio.
class OutfitsModeToggle extends StatelessWidget {
  final OutfitsViewMode mode;
  final ValueChanged<OutfitsViewMode> onChanged;

  const OutfitsModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _OutfitsModeChip(
              icon: Icons.swipe_rounded,
              label: l10n.outfitsModeSwipe,
              active: mode == OutfitsViewMode.swipe,
              onTap: () => onChanged(OutfitsViewMode.swipe),
            ),
            _OutfitsModeChip(
              icon: Icons.grid_view_rounded,
              label: l10n.outfitsModeBiblio,
              active: mode == OutfitsViewMode.biblio,
              onTap: () => onChanged(OutfitsViewMode.biblio),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutfitsModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _OutfitsModeChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: active ? AppColors.white : AppColors.textHint),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.white : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
