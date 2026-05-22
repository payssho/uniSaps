import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// Carte teasing UniSaps+ (suggestions IA, analyse photo).
class UnisapsPremiumTeaseCard extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onTap;

  const UnisapsPremiumTeaseCard({
    super.key,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Material(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPremium ? 'Suggestions IA' : 'UniSaps+',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isPremium
                      ? 'Génère 3 tenues adaptées à la météo du jour.'
                      : 'Analyse photo · 3 suggestions / matin · Badge premium',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    isPremium ? 'Ouvrir' : 'Découvrir',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
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
