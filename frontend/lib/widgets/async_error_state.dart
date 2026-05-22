import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// État d’erreur réseau / chargement avec message utilisateur et retry.
class AsyncErrorState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? subtitle;

  const AsyncErrorState({
    super.key,
    this.onRetry,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.textHint.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle ??
                  'Vérifie ta connexion et réessaie dans quelques instants.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
