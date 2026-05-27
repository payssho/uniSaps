import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/ui_navigation_provider.dart';
import '../screens/home/home_screen.dart';

Future<void> showPremiumUpgradeDialog(
  BuildContext context, {
  WidgetRef? ref,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.premiumDialogTitleFull,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bullet(l10n.premiumDialogBenefit1Full),
          _bullet(l10n.premiumDialogBenefit2Full),
          _bullet(l10n.premiumDialogBenefit3Full),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.premiumDialogPriceMonthlyFull,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.premiumDialogPriceLifetimeFull,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.premiumDialogActivateHint,
            style: TextStyle(
              height: 1.4,
              fontSize: 13,
              color: AppColors.textHint.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            l10n.commonLater,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            if (ref != null) {
              ref.read(selectedTabProvider.notifier).state = 3;
              ref.read(profileInfosTabRequestProvider.notifier).state++;
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.white,
          ),
          child: Text(l10n.premiumDialogCta),
        ),
      ],
    ),
  );
}

Widget _bullet(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
