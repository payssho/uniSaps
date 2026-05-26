import 'package:flutter/material.dart';

/// Seuil (px logiques) au-delà duquel on booste le décodage (grandes images).
const double _kLargeImageLogicalThreshold = 160;

/// Minimum de pixels physiques pour les visuels type détail / plein écran.
const int _kMinLargeImageCachePx = 1440;

int _physicalPixels(BuildContext context, double logical, {bool preferHighQuality = false}) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  var px = (logical * dpr).round();
  if (preferHighQuality || logical >= _kLargeImageLogicalThreshold) {
    px = (px * 1.25).round();
    if (px < _kMinLargeImageCachePx) return _kMinLargeImageCachePx;
  }
  return px;
}

/// Largeur cache mémoire (px physiques) pour un affichage net à la DPR de l'écran.
int? memCacheWidthFor(
  BuildContext context,
  double logicalWidth, {
  bool preferHighQuality = false,
}) {
  if (!logicalWidth.isFinite || logicalWidth <= 0) return null;
  return _physicalPixels(context, logicalWidth, preferHighQuality: preferHighQuality);
}

/// Hauteur cache mémoire (px physiques).
int? memCacheHeightFor(
  BuildContext context,
  double logicalHeight, {
  bool preferHighQuality = false,
}) {
  if (!logicalHeight.isFinite || logicalHeight <= 0) return null;
  return _physicalPixels(context, logicalHeight, preferHighQuality: preferHighQuality);
}
