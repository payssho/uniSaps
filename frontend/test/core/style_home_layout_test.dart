import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/core/style_home_layout.dart';
import 'package:unisaps/models/style_profile.dart';

void main() {
  group('homeSectionOrder', () {
    test('null profile returns default enum order', () {
      expect(homeSectionOrder(null), HomeSection.values);
    });

    test('goal_inspiration puts inspiration first when onboarding skipped', () {
      const profile = StyleProfile(
        goalInspiration: 5,
        goalWardrobe: 1,
        onboardingSkipped: true,
      );
      expect(homeSectionOrder(profile).first, HomeSection.inspiration);
    });

    test('archetype explorateur puts inspiration first', () {
      const profile = StyleProfile(archetype: 'explorateur');
      expect(homeSectionOrder(profile).first, HomeSection.inspiration);
    });

    test('goal_track_wear puts streak first when onboarding skipped', () {
      const profile = StyleProfile(
        goalTrackWear: 5,
        onboardingSkipped: true,
      );
      expect(homeSectionOrder(profile).first, HomeSection.streak);
    });
  });

  group('homeTabLogicalOrder', () {
    test('null profile keeps default tab order', () {
      expect(homeTabLogicalOrder(null), kDefaultHomeTabOrder);
    });

    test('archetype explorateur puts inspiration tab first', () {
      const profile = StyleProfile(archetype: 'explorateur');
      expect(homeTabLogicalOrder(profile).first, 2);
      expect(homeTabLogicalOrder(profile).last, 3);
    });

    test('goal_refine_style puts outfits tab first when skipped', () {
      const profile = StyleProfile(
        goalRefineStyle: 5,
        onboardingSkipped: true,
      );
      expect(homeTabLogicalOrder(profile).first, 1);
    });

    test('archetype apprenti_style puts outfits tab first', () {
      const profile = StyleProfile(archetype: 'apprenti_style');
      expect(homeTabLogicalOrder(profile).first, 1);
    });

    test('physical/logical mapping round-trips', () {
      const profile = StyleProfile(archetype: 'explorateur');
      final order = homeTabLogicalOrder(profile);
      for (var physical = 0; physical < order.length; physical++) {
        final logical = homeLogicalIndexForPhysical(order, physical);
        expect(homePhysicalIndexForLogical(order, logical), physical);
      }
    });
  });
}
