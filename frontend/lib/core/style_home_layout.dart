import '../models/style_profile.dart';

/// Sections de la home (priorité d’affichage selon le profil style).
enum HomeSection { dressing, inspiration, outfits, streak }

/// Ordre des sections : archétype si profil complété, sinon objectif dominant.
List<HomeSection> homeSectionOrder(StyleProfile? profile) {
  if (profile == null) {
    return HomeSection.values;
  }
  if (!profile.onboardingSkipped) {
    switch (profile.archetype) {
      case 'explorateur':
        return [
          HomeSection.inspiration,
          HomeSection.outfits,
          HomeSection.dressing,
          HomeSection.streak,
        ];
      case 'apprenti_style':
        return [
          HomeSection.outfits,
          HomeSection.dressing,
          HomeSection.inspiration,
          HomeSection.streak,
        ];
      case 'gestionnaire':
        return [
          HomeSection.dressing,
          HomeSection.outfits,
          HomeSection.inspiration,
          HomeSection.streak,
        ];
    }
  }
  switch (profile.dominantGoalKey) {
    case 'goal_inspiration':
      return [
        HomeSection.inspiration,
        HomeSection.outfits,
        HomeSection.dressing,
        HomeSection.streak,
      ];
    case 'goal_wardrobe':
      return [
        HomeSection.dressing,
        HomeSection.outfits,
        HomeSection.inspiration,
        HomeSection.streak,
      ];
    case 'goal_refine_style':
      return [
        HomeSection.outfits,
        HomeSection.dressing,
        HomeSection.inspiration,
        HomeSection.streak,
      ];
    case 'goal_track_wear':
      return [
        HomeSection.streak,
        HomeSection.outfits,
        HomeSection.inspiration,
        HomeSection.dressing,
      ];
    default:
      return HomeSection.values;
  }
}

/// Onglets logiques : 0 = Dressing, 1 = Outfits, 2 = Inspiration, 3 = Profil.
const List<int> kDefaultHomeTabOrder = [0, 1, 2, 3];

int _sectionToLogicalTab(HomeSection section) {
  switch (section) {
    case HomeSection.dressing:
      return 0;
    case HomeSection.outfits:
    case HomeSection.streak:
      return 1;
    case HomeSection.inspiration:
      return 2;
  }
}

/// Ordre physique des onglets (barre + PageView) dérivé de [homeSectionOrder].
List<int> homeTabLogicalOrder(StyleProfile? profile) {
  if (profile == null) {
    return List<int>.from(kDefaultHomeTabOrder);
  }
  final seen = <int>{};
  final order = <int>[];
  for (final section in homeSectionOrder(profile)) {
    final tab = _sectionToLogicalTab(section);
    if (seen.add(tab)) {
      order.add(tab);
    }
  }
  for (final tab in const [0, 1, 2]) {
    if (!seen.contains(tab)) {
      order.add(tab);
    }
  }
  order.add(3);
  return order;
}

int homePhysicalIndexForLogical(List<int> order, int logicalTab) {
  final idx = order.indexOf(logicalTab);
  return idx >= 0 ? idx : logicalTab.clamp(0, order.length - 1);
}

int homeLogicalIndexForPhysical(List<int> order, int physicalIndex) {
  if (physicalIndex < 0 || physicalIndex >= order.length) {
    return 0;
  }
  return order[physicalIndex];
}
