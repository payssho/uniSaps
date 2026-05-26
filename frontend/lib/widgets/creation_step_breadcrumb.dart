import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Étapes prédéfinies pour la création d’outfit.
const outfitCreationSteps = <(IconData, String)>[
  (Icons.checkroom_outlined, 'Pièces'),
  (Icons.photo_camera_outlined, 'Nom & photo'),
  (Icons.cloud_outlined, 'Météo'),
];

/// Étapes pour la création d’un post pub créateur.
const creatorPostCreationSteps = <(IconData, String)>[
  (Icons.checkroom_outlined, 'Pièces'),
  (Icons.photo_camera_outlined, 'Photo & nom'),
  (Icons.campaign_outlined, 'Publication'),
];

/// Fil d’Ariane réutilisable (outfit, post créateur, etc.).
class CreationStepBreadcrumb extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStep;
  final List<(IconData, String)> steps;

  const CreationStepBreadcrumb({
    super.key,
    required this.currentStep,
    required this.onStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: i <= currentStep
                      ? AppColors.accent.withValues(alpha: 0.55)
                      : AppColors.divider,
                ),
              ),
            Expanded(
              child: CreationStepPill(
                stepNumber: i + 1,
                icon: steps[i].$1,
                label: steps[i].$2,
                active: currentStep == i,
                completed: currentStep > i,
                onTap: () => onStep(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CreationStepPill extends StatelessWidget {
  final int stepNumber;
  final IconData icon;
  final String label;
  final bool active;
  final bool completed;
  final VoidCallback onTap;

  const CreationStepPill({
    super.key,
    required this.stepNumber,
    required this.icon,
    required this.label,
    required this.active,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = active
        ? AppColors.white
        : completed
            ? AppColors.accent
            : AppColors.textHint;
    final Color bg = active
        ? AppColors.accent
        : completed
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.surfaceVariant;
    final Color border = active
        ? AppColors.accent
        : completed
            ? AppColors.accent.withValues(alpha: 0.35)
            : Colors.transparent;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border, width: active || completed ? 1.5 : 0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (completed && !active)
                    Icon(Icons.check_circle_rounded, size: 14, color: fg)
                  else
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.white.withValues(alpha: 0.25)
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$stepNumber',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(icon, size: 14, color: fg),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
