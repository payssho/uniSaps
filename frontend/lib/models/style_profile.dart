import 'package:unisaps/core/style_profile_archetype.dart';

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
  final List<String> preferredStyles;
  final String usageFrequency;
  final String socialIntent;
  final String archetype;

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
    this.preferredStyles = const [],
    this.usageFrequency = 'weekly',
    this.socialIntent = 'undecided',
    this.archetype = 'gestionnaire',
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
      preferredStyles: _readStringList(map['preferred_styles']),
      usageFrequency: map['usage_frequency'] as String? ?? 'weekly',
      socialIntent: map['social_intent'] as String? ?? 'undecided',
      archetype: map['archetype'] as String? ?? 'gestionnaire',
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
        preferredStyles: const [],
        usageFrequency: 'weekly',
        socialIntent: 'undecided',
        archetype: 'gestionnaire',
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
        'preferred_styles': preferredStyles,
        'usage_frequency': usageFrequency,
        'social_intent': socialIntent,
        'archetype': archetype,
      };

  StyleProfile copyWith({
    int? goalWardrobe,
    int? goalInspiration,
    int? goalRefineStyle,
    int? goalTrackWear,
    String? identityStyle,
    int? audacity,
    String? fashionComfort,
    bool? onboardingSkipped,
    String? updatedAt,
    List<String>? preferredStyles,
    String? usageFrequency,
    String? socialIntent,
    String? archetype,
  }) {
    return StyleProfile(
      goalWardrobe: goalWardrobe ?? this.goalWardrobe,
      goalInspiration: goalInspiration ?? this.goalInspiration,
      goalRefineStyle: goalRefineStyle ?? this.goalRefineStyle,
      goalTrackWear: goalTrackWear ?? this.goalTrackWear,
      identityStyle: identityStyle ?? this.identityStyle,
      audacity: audacity ?? this.audacity,
      fashionComfort: fashionComfort ?? this.fashionComfort,
      onboardingSkipped: onboardingSkipped ?? this.onboardingSkipped,
      updatedAt: updatedAt ?? this.updatedAt,
      preferredStyles: preferredStyles ?? this.preferredStyles,
      usageFrequency: usageFrequency ?? this.usageFrequency,
      socialIntent: socialIntent ?? this.socialIntent,
      archetype: archetype ?? this.archetype,
    );
  }

  StyleProfile withComputedArchetype() =>
      copyWith(archetype: computeArchetype(this));

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

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}
