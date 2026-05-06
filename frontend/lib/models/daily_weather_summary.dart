/// Données météo jour courant (Open-Meteo, fuseau automatique).
class DailyWeatherSummary {
  final double latitude;
  final double longitude;
  final DateTime date;
  final int weatherCode;
  final double tempMin;
  final double tempMax;

  double get avgTemp => (tempMin + tempMax) / 2;

  const DailyWeatherSummary({
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.weatherCode,
    required this.tempMin,
    required this.tempMax,
  });
}
