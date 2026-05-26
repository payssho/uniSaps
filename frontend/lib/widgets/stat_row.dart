import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Cellule de statistique (profil perso, profil créateur).
class StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double valueFontSize;

  const StatCell({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.valueFontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
              height: 1,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

Widget statRowDivider() {
  return Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: AppColors.divider.withValues(alpha: 0.85),
  );
}
