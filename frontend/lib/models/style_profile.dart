class StyleProfile {
  final int goalWardrobe;
  final int goalInspiration;
  final int goalRefineStyle;
  final int goalTrackWear;
  final String identityStyle;
  final int audacity;
  final String fashionComfort;
  final bool onboardingSkipped;
  final String updatedAt;

  const StyleProfile({
    this.goalWardrobe = 3,
    this.goalInspiration = 3,
    this.goalRefineStyle = 3,
    this.goalTrackWear = 3,
    this.identityStyle = 'casual',
    this.audacity = 3,
    this.fashionComfort = 'balanced',
    this.onboardingSkipped = false,
    this.updatedAt = '',
  });

  factory StyleProfile.fromMap(Map<String, dynamic> map) {
    return StyleProfile(
      goalWardrobe: _readInt(map['goal_wardrobe'], 3),
      goalInspiration: _readInt(map['goal_inspiration'], 3),
      goalRefineStyle: _readInt(map['goal_refine_style'], 3),
      goalTrackWear: _readInt(map['goal_track_wear'], 3),
      identityStyle: map['identity_style'] as String? ?? 'casual',
      audacity: _readInt(map['audacity'], 3),
      fashionComfort: map['fashion_comfort'] as String? ?? 'balanced',
      onboardingSkipped: map['onboarding_skipped'] as bool? ?? false,
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  factory StyleProfile.defaults({bool skipped = false}) => StyleProfile(
        goalWardrobe: 3,
        goalInspiration: 3,
        goalRefineStyle: 3,
        goalTrackWear: 3,
        identityStyle: 'casual',
        audacity: 3,
        fashionComfort: 'balanced',
        onboardingSkipped: skipped,
        updatedAt: DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toMap() => {
        'goal_wardrobe': goalWardrobe,
        'goal_inspiration': goalInspiration,
        'goal_refine_style': goalRefineStyle,
        'goal_track_wear': goalTrackWear,
        'identity_style': identityStyle,
        'audacity': audacity,
        'fashion_comfort': fashionComfort,
        'onboarding_skipped': onboardingSkipped,
        'updated_at': updatedAt,
      };

  /// Clé snake_case de l'objectif le plus élevé (ex. `goal_wardrobe`).
  String get dominantGoalKey {
    final goals = <String, int>{
      'goal_wardrobe': goalWardrobe,
      'goal_inspiration': goalInspiration,
      'goal_refine_style': goalRefineStyle,
      'goal_track_wear': goalTrackWear,
    };
    return goals.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.round();
    return fallback;
  }
}
