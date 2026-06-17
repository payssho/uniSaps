import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/core/personalization_config.dart';
import 'package:unisaps/models/style_profile.dart';

void main() {
  test('explorateur → initialTab 2 and discover banner', () {
    const c = PersonalizationConfig(
      initialTab: 2,
      tutorialStartTab: 2,
      showInspirationDiscoverBanner: true,
      defaultInspirationExplorer: true,
    );
    expect(c.initialTab, 2);
    expect(c.showInspirationDiscoverBanner, isTrue);
  });

  test('fromProfile explorateur', () {
    const profile = StyleProfile(archetype: 'explorateur');
    final c = PersonalizationConfig.fromProfile(profile);
    expect(c.initialTab, 2);
    expect(c.defaultInspirationExplorer, isTrue);
    expect(c.showOutfitFromInspoCta, isTrue);
  });

  test('fromProfile gestionnaire shows dressing stats', () {
    const profile = StyleProfile(archetype: 'gestionnaire');
    final c = PersonalizationConfig.fromProfile(profile);
    expect(c.showDressingStatsCard, isTrue);
    expect(c.initialTab, 0);
  });

  test('fromProfile apprenti_style shows stylist promo', () {
    const profile = StyleProfile(archetype: 'apprenti_style');
    final c = PersonalizationConfig.fromProfile(profile);
    expect(c.showStylistPromoCard, isTrue);
    expect(c.initialTab, 1);
  });

  test('null or skipped → neutral', () {
    expect(PersonalizationConfig.fromProfile(null).initialTab, 0);
    expect(
      PersonalizationConfig.fromProfile(StyleProfile.defaults(skipped: true))
          .showDressingStatsCard,
      isFalse,
    );
  });
}
