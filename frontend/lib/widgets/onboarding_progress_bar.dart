import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class OnboardingProgressBar extends StatelessWidget
    implements PreferredSizeWidget {
  const OnboardingProgressBar({
    super.key,
    required this.step,
    required this.total,
  });

  final int step;
  final int total;

  static const double _kHeight = 4.0;

  @override
  Size get preferredSize => const Size.fromHeight(_kHeight);

  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
        value: step / total,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
        backgroundColor: AppColors.accent.withValues(alpha: 0.2),
        semanticsLabel: 'Étape $step sur $total',
      );
}
