/// Donnée météo pour une heure précise du jour courant.
class HourlyWeatherPoint {
  final DateTime time;
  final double temperatureC;
  final double apparentTemperatureC;
  final int weatherCode;
  final int precipitationProbabilityPct;
  final double precipitationMm;
  final double windSpeedKmh;
  final bool isDay;

  const HourlyWeatherPoint({
    required this.time,
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.weatherCode,
    required this.precipitationProbabilityPct,
    required this.precipitationMm,
    required this.windSpeedKmh,
    required this.isDay,
  });
}

/// Données météo jour courant (Open-Meteo, fuseau automatique).
class DailyWeatherSummary {
  final double latitude;
  final double longitude;
  final DateTime date;
  final int weatherCode;
  final double tempMin;
  final double tempMax;

  /// Nom de la ville résolu via reverse-geocoding (peut être vide).
  final String cityName;

  /// Lever / coucher du soleil pour la position courante.
  final DateTime? sunrise;
  final DateTime? sunset;

  /// Température et code météo « courant » à l’heure du fetch.
  final double? currentTemperatureC;
  final double? currentApparentTemperatureC;
  final int? currentWeatherCode;
  final double? currentWindSpeedKmh;
  final int? currentRelativeHumidityPct;
  final bool? currentIsDay;

  /// Données horaires (24 points typiques) pour la journée courante.
  final List<HourlyWeatherPoint> hourly;

  /// Moment du fetch (utile pour invalider les caches).
  final DateTime fetchedAt;

  double get avgTemp => (tempMin + tempMax) / 2;

  const DailyWeatherSummary({
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.weatherCode,
    required this.tempMin,
    required this.tempMax,
    this.cityName = '',
    this.sunrise,
    this.sunset,
    this.currentTemperatureC,
    this.currentApparentTemperatureC,
    this.currentWeatherCode,
    this.currentWindSpeedKmh,
    this.currentRelativeHumidityPct,
    this.currentIsDay,
    this.hourly = const [],
    required this.fetchedAt,
  });
}
