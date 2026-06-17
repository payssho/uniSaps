import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/core/style_profile_archetype.dart';
import 'package:unisaps/models/style_profile.dart';

void main() {
  test('defaults when skipped sets onboardingSkipped', () {
    final p = StyleProfile.defaults(skipped: true);
    expect(p.goalWardrobe, 3);
    expect(p.identityStyle, 'casual');
    expect(p.onboardingSkipped, true);
  });

  test('fromMap parses preferred_styles, usage_frequency, social_intent, archetype',
      () {
    final profile = StyleProfile.fromMap({
      'preferred_styles': ['casual', 'minimal'],
      'usage_frequency': 'daily',
      'social_intent': 'friends',
      'archetype': 'explorateur',
    });
    expect(profile.preferredStyles, ['casual', 'minimal']);
    expect(profile.usageFrequency, 'daily');
    expect(profile.socialIntent, 'friends');
    expect(profile.archetype, 'explorateur');
  });

  test('defaults for new Fable fields', () {
    const profile = StyleProfile();
    expect(profile.preferredStyles, isEmpty);
    expect(profile.usageFrequency, 'weekly');
    expect(profile.socialIntent, 'undecided');
    expect(profile.archetype, 'gestionnaire');
  });

  test('withComputedArchetype sets archetype from goals', () {
    const profile = StyleProfile(
      goalInspiration: 5,
      goalWardrobe: 3,
      goalRefineStyle: 3,
      goalTrackWear: 3,
      archetype: 'gestionnaire',
    );
    final updated = profile.withComputedArchetype();
    expect(updated.archetype, computeArchetype(profile));
    expect(updated.archetype, 'explorateur');
  });
}
