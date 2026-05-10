import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

Future<void> showPremiumUpgradeDialog(BuildContext context) {
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
          const Expanded(
            child: Text(
              'Passe en UniSaps+',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'L’analyse IA des photos de vêtements et les suggestions d’outfits par IA sont réservées aux abonnés UniSaps+. '
        'Le paiement pourra être ajouté plus tard — pour l’instant, contacte l’équipe ou modifie ton statut dans Firestore pour tester.',
        style: TextStyle(
          height: 1.45,
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Plus tard',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Compris'),
        ),
      ],
    ),
  );
}
