import '../core/constants/weather_catalog.dart';
import 'generated/app_localizations.dart';

String categoryLabelL10n(AppLocalizations l, String key) {
  switch (key) {
    case 'headwear':
      return l.categoryHeadwear;
    case 'top':
      return l.categoryTop;
    case 'outerwear':
      return l.categoryOuterwear;
    case 'bottom':
      return l.categoryBottom;
    case 'shoes':
      return l.categoryShoes;
    case 'accessory':
      return l.categoryAccessory;
    default:
      return key;
  }
}

String seasonLabelL10n(AppLocalizations l, String key) {
  switch (key) {
    case 'winter':
      return l.seasonWinter;
    case 'spring':
      return l.seasonSpring;
    case 'summer':
      return l.seasonSummer;
    case 'autumn':
      return l.seasonAutumn;
    default:
      return key;
  }
}

String creationWeatherLabelL10n(AppLocalizations l, String id) {
  switch (id) {
    case 'beau':
      return l.weatherNice;
    case 'nuageux':
      return l.weatherCloudy;
    case 'pluie':
      return l.weatherRain;
    case 'neige':
      return l.weatherSnow;
    case 'orage':
      return l.weatherStorm;
    default:
      return id;
  }
}

/// Libellé court météo (détail, widgets) à partir des tags du jour.
String weatherVisualShortLabelL10n(AppLocalizations l, Set<String> tags) {
  if (tags.contains(WeatherTagKeys.thunderstorm)) return l.weatherStorm;
  if (tags.contains(WeatherTagKeys.rain) ||
      tags.contains(WeatherTagKeys.drizzle)) {
    return l.weatherRain;
  }
  if (tags.contains(WeatherTagKeys.snow)) return l.weatherSnow;
  if (tags.contains(WeatherTagKeys.fog)) return l.weatherFog;
  if (tags.contains(WeatherTagKeys.clear)) return l.weatherNice;
  if (tags.contains(WeatherTagKeys.partlyCloudy)) {
    return l.weatherPartlyClear;
  }
  if (tags.contains(WeatherTagKeys.cloudy)) return l.weatherCloudy;
  return l.weatherVariable;
}

/// Libellé affiché pour une couleur (clé stable ou ancien nom FR en base).
String colorDisplayNameL10n(AppLocalizations l, String nameOrId) {
  final n = nameOrId.trim();
  switch (n) {
    case 'noir':
    case 'Noir':
      return l.colorBlack;
    case 'blanc':
    case 'Blanc':
      return l.colorWhite;
    case 'gris':
    case 'Gris':
      return l.colorGrey;
    case 'gris clair':
    case 'Gris clair':
      return l.colorLightGrey;
    case 'gris foncé':
    case 'Gris foncé':
      return l.colorDarkGrey;
    case 'beige':
    case 'Beige':
      return l.colorBeige;
    case 'camel':
    case 'Camel':
      return l.colorCamel;
    case 'marron':
    case 'Marron':
      return l.colorBrown;
    case 'bleu':
    case 'Bleu':
      return l.colorBlue;
    case 'rouge':
    case 'Rouge':
      return l.colorRed;
    case 'vert':
    case 'Vert':
      return l.colorGreen;
    case 'jaune':
    case 'Jaune':
      return l.colorYellow;
    case 'orange':
    case 'Orange':
      return l.colorOrange;
    case 'rose':
    case 'Rose':
      return l.colorPink;
    case 'violet':
    case 'Violet':
      return l.colorPurple;
    case 'multicolore':
    case 'Multicolore':
      return l.colorMulticolor;
    default:
      return nameOrId;
  }
}

String accountVisibilityL10n(AppLocalizations l, bool isPrivate) =>
    isPrivate ? l.profileAccountPrivate : l.profileAccountPublic;

String premiumStatusL10n(AppLocalizations l, bool isPremium) =>
    isPremium ? l.profilePremiumActive : l.profilePremiumFree;

/// Libellé UI pour un style IA ([stylePrompts] / backend).
String stylePromptLabelL10n(AppLocalizations l, String apiStyle) {
  switch (apiStyle) {
    case 'Simple':
      return l.styleSimple;
    case 'Coloré':
      return l.styleColorful;
    case 'Classe':
      return l.styleClassy;
    case 'Professionnel':
      return l.styleProfessional;
    case 'Décontracté':
      return l.styleCasual;
    case 'Streetwear':
      return l.styleStreetwear;
    case 'Sportif':
      return l.styleSporty;
    case 'Soirée':
      return l.styleEvening;
    default:
      return apiStyle;
  }
}
