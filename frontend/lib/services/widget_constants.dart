/// Clés SharedPreferences partagées Flutter ↔ widgets Android (home_widget).
abstract final class WidgetDataKeys {
  static const authUid = 'auth_uid';
  static const hasChosenOutfitToday = 'has_chosen_outfit_today';
  static const dailyOutfitId = 'daily_outfit_id';
  static const dailyOutfitName = 'daily_outfit_name';
  static const currentStreak = 'current_streak';
  static const weatherTemp = 'weather_temp';
  static const weatherLabel = 'weather_label';
  static const suitableOutfitsCount = 'suitable_outfits_count';
  static const hasPostedToday = 'has_posted_today';

  /// Chemins fichiers locaux image, séparés par | (carrousel outfits).
  static const outfitCarouselPaths = 'outfit_carousel_paths';
  static const outfitCarouselNames = 'outfit_carousel_names';

  /// Idem pour les pièces du dressing.
  static const garmentCarouselPaths = 'garment_carousel_paths';
  static const garmentCarouselNames = 'garment_carousel_names';

  /// Widget « choix du jour » : tenues compatibles (swipe / météo).
  static const suitablePickCarouselPaths = 'suitable_pick_carousel_paths';
  static const suitablePickCarouselNames = 'suitable_pick_carousel_names';
}

/// Noms courts des classes Kotlin `AppWidgetProvider` (suffixe du FQCN).
abstract final class WidgetAndroidNames {
  static const outfitCarousel = 'OutfitCarouselWidgetProvider';
  static const dressingCarousel = 'DressingCarouselWidgetProvider';
  static const todayPick = 'TodayPickWidgetProvider';
}

/// Deep links lancés depuis les widgets.
abstract final class WidgetDeepLinks {
  static const outfits = 'unisaps://home?tab=outfits';
  static const outfitsSwipe = 'unisaps://home?tab=outfits&mode=swipe';
  static const dressing = 'unisaps://home?tab=dressing';
}
