import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/core/style_profile_archetype.dart';
import 'package:unisaps/models/style_profile.dart';

void main() {
  test('wardrobe dominant (5) → gestionnaire', () {
    const profile = StyleProfile(
      goalWardrobe: 5,
      goalInspiration: 3,
      goalRefineStyle: 3,
      goalTrackWear: 3,
    );
    expect(computeArchetype(profile), 'gestionnaire');
  });

  test('track dominant (5) → gestionnaire', () {
    const profile = StyleProfile(
      goalWardrobe: 3,
      goalInspiration: 3,
      goalRefineStyle: 3,
      goalTrackWear: 5,
    );
    expect(computeArchetype(profile), 'gestionnaire');
  });

  test('inspiration dominant (5) → explorateur', () {
    const profile = StyleProfile(
      goalWardrobe: 3,
      goalRefineStyle: 3,
      goalTrackWear: 3,
      goalInspiration: 5,
    );
    expect(computeArchetype(profile), 'explorateur');
  });

  test('refine dominant (5) → apprenti_style', () {
    const profile = StyleProfile(
      goalWardrobe: 3,
      goalInspiration: 3,
      goalTrackWear: 3,
      goalRefineStyle: 5,
    );
    expect(computeArchetype(profile), 'apprenti_style');
  });

  test('tie-break: all 5s → apprenti_style', () {
    const profile = StyleProfile(
      goalWardrobe: 5,
      goalInspiration: 5,
      goalRefineStyle: 5,
      goalTrackWear: 5,
    );
    expect(computeArchetype(profile), 'apprenti_style');
  });

  test('tie-break: wardrobe+inspiration+track all 5 → explorateur', () {
    const profile = StyleProfile(
      goalWardrobe: 5,
      goalInspiration: 5,
      goalRefineStyle: 3,
      goalTrackWear: 5,
    );
    expect(computeArchetype(profile), 'explorateur');
  });

  test('StyleProfile.defaults(skipped: true) → gestionnaire', () {
    final profile = StyleProfile.defaults(skipped: true);
    expect(computeArchetype(profile), 'gestionnaire');
  });
}
