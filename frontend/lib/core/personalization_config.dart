import '../models/style_profile.dart';

/// Configuration UI dérivée du profil style (archétype Fable).
class PersonalizationConfig {
  final int initialTab;
  final int tutorialStartTab;
  final bool showDressingStatsCard;
  final bool showInspirationDiscoverBanner;
  final bool defaultInspirationExplorer;
  final bool showStylistPromoCard;
  final bool showOutfitFromInspoCta;

  const PersonalizationConfig({
    this.initialTab = 0,
    this.tutorialStartTab = 0,
    this.showDressingStatsCard = false,
    this.showInspirationDiscoverBanner = false,
    this.defaultInspirationExplorer = false,
    this.showStylistPromoCard = false,
    this.showOutfitFromInspoCta = false,
  });

  const PersonalizationConfig.neutral()
      : initialTab = 0,
        tutorialStartTab = 0,
        showDressingStatsCard = false,
        showInspirationDiscoverBanner = false,
        defaultInspirationExplorer = false,
        showStylistPromoCard = false,
        showOutfitFromInspoCta = false;

  factory PersonalizationConfig.fromProfile(StyleProfile? profile) {
    if (profile == null || profile.onboardingSkipped) {
      return const PersonalizationConfig.neutral();
    }
    switch (profile.archetype) {
      case 'explorateur':
        return const PersonalizationConfig(
          initialTab: 2,
          tutorialStartTab: 2,
          showInspirationDiscoverBanner: true,
          defaultInspirationExplorer: true,
          showOutfitFromInspoCta: true,
        );
      case 'apprenti_style':
        return const PersonalizationConfig(
          initialTab: 1,
          tutorialStartTab: 1,
          showStylistPromoCard: true,
        );
      case 'gestionnaire':
      default:
        return const PersonalizationConfig(
          initialTab: 0,
          tutorialStartTab: 0,
          showDressingStatsCard: true,
        );
    }
  }
}
