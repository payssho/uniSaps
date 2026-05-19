import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CategoryChip extends StatefulWidget {
  final String label;
  final Widget Function(Color iconColor) leadingBuilder;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.leadingBuilder,
    required this.selected,
    required this.onTap,
  });

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.93),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: widget.selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.selected ? AppColors.accent : AppColors.divider,
            width: widget.selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.leadingBuilder(
              widget.selected ? AppColors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.selected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
