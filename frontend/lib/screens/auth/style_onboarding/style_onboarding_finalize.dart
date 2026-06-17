import '../../../models/style_profile.dart';

/// Profil prêt pour Firestore (archétype calculé, preferred_styles fallback).
StyleProfile finalizeStyleProfile(StyleProfile draft, {bool skipped = false}) {
  final preferred = draft.preferredStyles.isEmpty
      ? [draft.identityStyle]
      : List<String>.from(draft.preferredStyles);
  return draft
      .copyWith(
        preferredStyles: preferred,
        onboardingSkipped: skipped,
        updatedAt: DateTime.now().toIso8601String(),
      )
      .withComputedArchetype();
}
