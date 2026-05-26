import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radii.dart';

/// Shell unifié pour les bottom sheets (handle, fond, coins).
class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final double maxHeightFraction;
  final bool showHandle;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.maxHeightFraction = 0.92,
    this.showHandle = true,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    double maxHeightFraction = 0.92,
    bool showHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppBottomSheet(
        maxHeightFraction: maxHeightFraction,
        showHandle: showHandle,
        child: child,
      ),
    );
  }

  static Widget sheetHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.textHint.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * maxHeightFraction;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadii.sheet),
            ),
          ),
          child: showHandle
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: sheetHandle()),
                    Flexible(child: child),
                  ],
                )
              : child,
        ),
      ),
    );
  }
}
