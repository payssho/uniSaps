import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Clés stables pour Firestore (`seasons`, `weather_tags`).
class SeasonKeys {
  static const winter = 'winter';
  static const spring = 'spring';
  static const summer = 'summer';
  static const autumn = 'autumn';

  static const all = [winter, spring, summer, autumn];

  static String labelFr(String key) {
    switch (key) {
      case winter:
        return 'Hiver';
      case spring:
        return 'Printemps';
      case summer:
        return 'Été';
      case autumn:
        return 'Automne';
      default:
        return key;
    }
  }

  /// Saison calendaire (hémisphère nord - France par défaut).
  static String forLocalDate(DateTime d) {
    final m = d.month;
    if (m == 12 || m <= 2) return winter;
    if (m <= 5) return spring;
    if (m <= 8) return summer;
    return autumn;
  }
}

/// Tags météo / ressenti (cumulables sur un même outfit).
class WeatherTagKeys {
  static const clear = 'clear';
  static const partlyCloudy = 'partly_cloudy';
  static const cloudy = 'cloudy';
  static const fog = 'fog';
  static const drizzle = 'drizzle';
  static const rain = 'rain';
  static const snow = 'snow';
  static const thunderstorm = 'thunderstorm';
  static const cold = 'cold';
  static const mild = 'mild';
  static const warm = 'warm';
  static const hot = 'hot';

  static const allWeather = [
    clear,
    partlyCloudy,
    cloudy,
    fog,
    drizzle,
    rain,
    snow,
    thunderstorm,
    cold,
    mild,
    warm,
    hot,
  ];

  /// Choix très simple à l’écran de création (plusieurs peuvent être cochées).
  static const creationSimpleWeatherIds = [
    'beau',
    'nuageux',
    'pluie',
    'neige',
  ];

  /// Libellé court pour création outfit.
  static String creationSimpleLabelFr(String id) {
    switch (id) {
      case 'beau':
        return 'Beau temps';
      case 'nuageux':
        return 'Nuageux';
      case 'pluie':
        return 'Pluie';
      case 'neige':
        return 'Neige';
      case 'orage':
        return 'Orage';
      default:
        return id;
    }
  }

  /// Tags envoyés dans Firestore (compatibles avec le matching Open-Meteo du jour).
  static List<String> tagsForCreationPreset(String id) {
    switch (id) {
      case 'beau':
        return [clear, partlyCloudy];
      case 'nuageux':
        return [cloudy, partlyCloudy];
      case 'pluie':
        return [rain, drizzle];
      case 'neige':
        return [snow];
      case 'orage':
        return [thunderstorm];
      default:
        return [];
    }
  }

  static List<String> expandCreationSimplePresets(Set<String> presetIds) {
    final merged = <String>{};
    for (final id in presetIds) {
      merged.addAll(tagsForCreationPreset(id));
    }
    final out = merged.toList()..sort();
    return out;
  }

  static String labelFr(String key) {
    switch (key) {
      case clear:
        return 'Dégagé / soleil';
      case partlyCloudy:
        return 'Nuageux partiel';
      case cloudy:
        return 'Couvert';
      case fog:
        return 'Brouillard';
      case drizzle:
        return 'Bruine';
      case rain:
        return 'Pluie';
      case snow:
        return 'Neige';
      case thunderstorm:
        return 'Orage';
      case cold:
        return 'Froid';
      case mild:
        return 'Doux';
      case warm:
        return 'Chaud';
      case hot:
        return 'Très chaud';
      default:
        return key;
    }
  }

  /// Codes WMO Open-Meteo (daily weather_code).
  /// https://open-meteo.com/en/docs
  static Set<String> fromWmoCode(int code) {
    final tags = <String>{};
    if (code == 0) {
      tags.add(clear);
    } else if (code == 1) {
      tags.add(clear);
      tags.add(partlyCloudy);
    } else if (code == 2) {
      tags.add(partlyCloudy);
    } else if (code == 3) {
      tags.add(cloudy);
    } else if (code == 45 || code == 48) {
      tags.add(fog);
      tags.add(cloudy);
    } else if ((code >= 51 && code <= 57) || code == 56 || code == 57) {
      tags.add(drizzle);
    } else if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
      tags.add(rain);
    } else if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
      tags.add(snow);
    }
    // Orages / grêle - intervalles officiels mélangés : on prend 95+
    if (code >= 95) {
      tags.add(thunderstorm);
      tags.add(rain);
    }
    return tags;
  }

  /// Ressenti température (°C), moyenne min/max journée.
  static Set<String> fromTemperatureBand(double avgCelsius) {
    final t = avgCelsius;
    if (t < 8) return {cold};
    if (t < 14) return {mild};
    if (t < 22) return {warm};
    return {hot};
  }

  /// Regroupe conditions du jour pour comparaison avec les tags outfit.
  static Set<String> dayContext({
    required int weatherCode,
    required double tempMin,
    required double tempMax,
  }) {
    final avg = (tempMin + tempMax) / 2;
    final s = {...fromWmoCode(weatherCode), ...fromTemperatureBand(avg)};
    return s.isEmpty ? {partlyCloudy} : s;
  }

  /// Icône Material pour représentation synthétique.
  static WeatherVisual visualFor(Set<String> tags) {
    if (tags.contains(thunderstorm)) {
      return const WeatherVisual(Icons.bolt_rounded, 'Orage');
    }
    if (tags.contains(rain) || tags.contains(drizzle)) {
      return const WeatherVisual(Icons.umbrella_rounded, 'Pluie');
    }
    if (tags.contains(snow)) {
      return const WeatherVisual(Icons.ac_unit_rounded, 'Neige');
    }
    if (tags.contains(fog)) {
      return const WeatherVisual(Icons.cloud_rounded, 'Brouillard');
    }
    if (tags.contains(clear)) {
      return const WeatherVisual(Icons.wb_sunny_rounded, 'Beau temps');
    }
    if (tags.contains(partlyCloudy)) {
      return const WeatherVisual(Icons.wb_cloudy_rounded, 'Éclaircies');
    }
    if (tags.contains(cloudy)) {
      return const WeatherVisual(Icons.cloud_rounded, 'Nuageux');
    }
    return const WeatherVisual(Icons.help_outline_rounded, 'Temps variable');
  }
}

class WeatherVisual {
  final IconData icon;
  final String shortLabel;

  const WeatherVisual(this.icon, this.shortLabel);
}

String formatTempRange(double minC, double maxC) {
  final a = minC.round();
  final b = maxC.round();
  return '${math.min(a, b)}° / ${math.max(a, b)}°';
}
