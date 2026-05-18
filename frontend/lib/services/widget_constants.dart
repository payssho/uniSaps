/// Clés SharedPreferences partagées Flutter ↔ widgets Android (home_widget).
abstract final class WidgetDataKeys {
  static const authUid = 'auth_uid';
  static const hasChosenOutfitToday = 'has_chosen_outfit_today';
  static const dailyOutfitId = 'daily_outfit_id';
  static const dailyOutfitName = 'daily_outfit_name';
  static const currentStreak = 'current_streak';
  static const dailyPhotoPath = 'daily_photo_path';
  static const garmentThumbPaths = 'garment_thumb_paths';
  static const weatherTemp = 'weather_temp';
  static const weatherLabel = 'weather_label';
  static const suitableOutfitsCount = 'suitable_outfits_count';
  static const hasPostedToday = 'has_posted_today';
  static const inspiImagePath = 'inspi_image_path';
  static const inspiUsername = 'inspi_username';
  static const inspiHasContent = 'inspi_has_content';
}

/// Noms des providers Android (classe Kotlin sans package).
abstract final class WidgetAndroidNames {
  static const dailyOutfit = 'DailyOutfitWidgetProvider';
  static const pickOutfit = 'PickOutfitWidgetProvider';
  static const inspi = 'InspiWidgetProvider';
}

/// Deep links lancés depuis les widgets.
abstract final class WidgetDeepLinks {
  static const outfits = 'unisaps://home?tab=outfits';
  static const outfitsSwipe = 'unisaps://home?tab=outfits&mode=swipe';
  static const inspo = 'unisaps://home?tab=inspo';
}
