import 'package:unisaps/models/style_profile.dart';

/// Calcule l'archétype utilisateur à partir des objectifs style du profil.
///
/// Priorité en cas d'égalité : refine > inspiration > track > wardrobe.
String computeArchetype(StyleProfile profile) {
  if (profile.onboardingSkipped) return 'gestionnaire';

  final goals = [
    (profile.goalRefineStyle, 'apprenti_style'),
    (profile.goalInspiration, 'explorateur'),
    (profile.goalTrackWear, 'gestionnaire'),
    (profile.goalWardrobe, 'gestionnaire'),
  ];

  final maxValue = goals.map((g) => g.$1).reduce((a, b) => a > b ? a : b);

  for (final (value, archetype) in goals) {
    if (value == maxValue) return archetype;
  }

  return 'gestionnaire';
}
