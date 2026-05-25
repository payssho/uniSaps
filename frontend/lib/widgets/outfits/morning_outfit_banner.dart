import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/l10n_context.dart';

/// Bandeau de choix du parcours matin (Swipe vs Bibliothèque).
class MorningOutfitBanner extends StatelessWidget {
  final VoidCallback onSwipe;
  final VoidCallback onBibliotheque;
  final VoidCallback? onAiSuggestions;
  final bool isPremium;

  const MorningOutfitBanner({
    super.key,
    required this.onSwipe,
    required this.onBibliotheque,
    this.onAiSuggestions,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.scrimLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.outfitsMorningTitle,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.outfitsMorningSubtitle,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSwipe,
                    icon: const Icon(Icons.swipe_rounded, size: 20),
                    label: Text(l10n.outfitsMorningSwipe),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onBibliotheque,
                    icon: const Icon(Icons.grid_view_rounded, size: 20),
                    label: Text(l10n.outfitsMorningBiblio),
                  ),
                ),
              ],
            ),
            if (onAiSuggestions != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onAiSuggestions,
                icon: Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: isPremium ? AppColors.accent : AppColors.textHint,
                ),
                label: Text(
                  isPremium
                      ? l10n.outfitsMorningAi
                      : l10n.outfitsMorningAiDiscover,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isPremium ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
