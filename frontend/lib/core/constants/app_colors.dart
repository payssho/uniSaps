import 'package:flutter/material.dart';

/// Couleurs globales : uniquement la palette produit (hex officiels).
class AppColors {
  AppColors._();

  // ── Palette brute ─────────────────────────────────────────────────────────
  static const graphite = Color(0xFF353535);
  static const stormyTeal = Color(0xFF3C6E71);
  static const white = Color(0xFFFFFFFF);
  static const alabasterGrey = Color(0xFFD9D9D9);
  static const yaleBlue = Color(0xFF284B63);

  // ── Sémantique UI (dérivée uniquement de cette palette) ───────────────────
  static const primary = yaleBlue;
  static const secondary = graphite;
  static const accent = stormyTeal;

  /// Pour dégradés légers (palette : blanc ↔ teal).
  static const accentLight = white;

  static const background = alabasterGrey;
  static const surface = white;
  static const surfaceVariant = alabasterGrey;

  static const textPrimary = graphite;
  static const textSecondary = yaleBlue;
  static const textHint = stormyTeal;

  static const divider = alabasterGrey;

  /// États : hiérarchie distincte avec les 5 teintes seulement.
  static const success = stormyTeal;
  static const warning = yaleBlue;
  static const error = graphite;

  static const shimmerBase = alabasterGrey;
  static const shimmerHighlight = white;

  static const cardGradientStart = white;
  static const cardGradientEnd = alabasterGrey;

  /// Ombrages / scrims (graphite, même teinte de base).
  static Color get scrimLight => graphite.withValues(alpha: 0.08);

  static Color get scrimMedium => graphite.withValues(alpha: 0.35);

  static Color get scrimStrong => graphite.withValues(alpha: 0.55);

  static Color get scrimHeavy => graphite.withValues(alpha: 0.72);
}
