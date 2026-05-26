import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

enum AppEmptyStateSize { standard, compact }

/// État vide unifié (onglets, grilles, listes).
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final AppEmptyStateSize size;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.size = AppEmptyStateSize.standard,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size == AppEmptyStateSize.standard ? 72.0 : 48.0;
    final titleStyle = size == AppEmptyStateSize.standard
        ? TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.92),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          )
        : AppTextStyles.bodySecondary;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(size == AppEmptyStateSize.standard ? 40 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: AppColors.textHint.withValues(
                alpha: size == AppEmptyStateSize.standard ? 0.28 : 0.35,
              ),
            ),
            SizedBox(height: size == AppEmptyStateSize.standard ? 20 : 12),
            Text(title, style: titleStyle, textAlign: TextAlign.center),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  color: AppColors.textHint.withValues(alpha: 0.82),
                  fontSize: size == AppEmptyStateSize.standard ? 14 : 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: size == AppEmptyStateSize.standard ? 20 : 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
