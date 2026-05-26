import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/color_service.dart';

/// Pastilles de couleur + libellé (détail vêtement, profil ami).
class GarmentColorsWrap extends StatelessWidget {
  final List<String> colors;
  final double swatchSize;
  final double fontSize;

  const GarmentColorsWrap({
    super.key,
    required this.colors,
    this.swatchSize = 20,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((colorName) {
        final option = ColorService.resolveColorOption(colorName);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: swatchSize,
              height: swatchSize,
              decoration: BoxDecoration(
                color: option.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: option.color == AppColors.white ||
                          option.color == Colors.transparent
                      ? AppColors.divider
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.graphite.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: option.color == Colors.transparent
                  ? Center(
                      child: Container(
                        width: swatchSize * 0.7,
                        height: swatchSize * 0.7,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.graphite,
                              AppColors.stormyTeal,
                              AppColors.white,
                              AppColors.alabasterGrey,
                              AppColors.yaleBlue,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              colorName,
              style: TextStyle(
                fontSize: fontSize,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
