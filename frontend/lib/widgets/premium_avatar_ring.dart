import 'package:flutter/material.dart';

/// Anneau dégradé autour d’un avatar pour les comptes Premium (visible profil + posts).
class PremiumAvatarRing extends StatelessWidget {
  const PremiumAvatarRing({
    super.key,
    required this.isPremium,
    required this.child,
    this.padding = 3,
  });

  final bool isPremium;
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    if (!isPremium) return child;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE082),
            Color(0xFFFFA000),
            Color(0xFFFF6F00),
            Color(0xFFFFC107),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66FF9800),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
