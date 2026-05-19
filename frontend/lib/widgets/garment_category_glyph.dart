import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Icônes silhouettes pour les catégories vestimentaires (Material ne propose pas
/// de glyphes aussi littéraux). Accessoires : montre Material comme avant.
class GarmentCategoryGlyph extends StatelessWidget {
  final String categoryKey;
  final Color color;
  final double size;

  const GarmentCategoryGlyph({
    super.key,
    required this.categoryKey,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    switch (categoryKey) {
      case 'accessory':
        return Icon(Icons.watch_outlined, size: size, color: color);
      default:
        return CustomPaint(
          size: Size(size, size),
          painter: _GarmentCategoryPainter(
            categoryKey: categoryKey,
            color: color,
          ),
        );
    }
  }
}

class _GarmentCategoryPainter extends CustomPainter {
  _GarmentCategoryPainter({
    required this.categoryKey,
    required this.color,
  });

  final String categoryKey;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final s = size.shortestSide / 24.0;
    canvas.save();
    canvas.translate((size.width - 24 * s) / 2, (size.height - 24 * s) / 2);
    canvas.scale(s);

    switch (categoryKey) {
      case 'shoes':
        _drawShoe(canvas, paint);
        break;
      case 'bottom':
        _drawPants(canvas, paint);
        break;
      case 'top':
        _drawShirt(canvas, paint, longCoat: false);
        break;
      case 'outerwear':
        _drawShirt(canvas, paint, longCoat: true);
        break;
      case 'headwear':
        _drawCap(canvas, paint);
        break;
      default:
        _drawFallback(canvas, paint);
        break;
    }

    canvas.restore();
  }

  void _drawShoe(Canvas canvas, Paint paint) {
    final shoe = Path()
      ..moveTo(4, 15)
      ..cubicTo(4, 11.5, 7.5, 9.8, 12.5, 9)
      ..lineTo(17.5, 8.6)
      ..cubicTo(20.2, 8.4, 21.6, 10.2, 21.6, 13)
      ..lineTo(21.2, 17)
      ..cubicTo(20.6, 18.8, 17.8, 19.4, 13.5, 19)
      ..lineTo(7.2, 18)
      ..cubicTo(5, 17.5, 4, 16.3, 4, 15)
      ..close();
    canvas.drawPath(shoe, paint);
  }

  void _drawPants(Canvas canvas, Paint paint) {
    final pants = Path()
      ..moveTo(8, 5)
      ..lineTo(16, 5)
      ..lineTo(16.8, 6)
      ..lineTo(16.2, 19)
      ..lineTo(13.2, 19)
      ..lineTo(12.4, 8)
      ..lineTo(11.6, 8)
      ..lineTo(10.8, 19)
      ..lineTo(7.8, 19)
      ..lineTo(7.2, 6)
      ..close();
    canvas.drawPath(pants, paint);
  }

  void _drawShirt(Canvas canvas, Paint paint, {required bool longCoat}) {
    final bottom = longCoat ? 18.5 : 15.5;
    final sleeveOut = longCoat ? 5.8 : 6.8;
    final sleeveTop = longCoat ? 5.2 : 5.5;
    final shirt = Path()
      ..moveTo(12, 5.2)
      ..lineTo(9.2, 6)
      ..lineTo(sleeveOut, sleeveTop + 1.8)
      ..lineTo(6.6, 9.4)
      ..lineTo(8.8, 10.6)
      ..lineTo(9, bottom)
      ..lineTo(15, bottom)
      ..lineTo(15.2, 10.6)
      ..lineTo(17.4, 9.4)
      ..lineTo(24 - sleeveOut, sleeveTop + 1.8)
      ..lineTo(14.8, 6)
      ..lineTo(12, 5.2)
      ..close();
    canvas.drawPath(shirt, paint);
    if (longCoat) {
      final collar = Path()
        ..moveTo(10.5, 6.2)
        ..lineTo(12, 7.6)
        ..lineTo(13.5, 6.2);
      canvas.drawPath(
        collar,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawCap(Canvas canvas, Paint paint) {
    canvas.drawArc(
      const Rect.fromLTWH(5, 5, 14, 11),
      math.pi,
      math.pi,
      true,
      paint,
    );
    final brim = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.5, 13.5, 17, 3.2),
      const Radius.circular(1.2),
    );
    canvas.drawRRect(brim, paint);
  }

  void _drawFallback(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(12, 12), 8, paint);
  }

  @override
  bool shouldRepaint(covariant _GarmentCategoryPainter oldDelegate) {
    return oldDelegate.categoryKey != categoryKey || oldDelegate.color != color;
  }
}
