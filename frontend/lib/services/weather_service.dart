import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/daily_weather_summary.dart';

/// Fallback France (Paris) si géolocalisation refusée.
const double kWeatherFallbackLat = 48.8566;
const double kWeatherFallbackLon = 2.3522;

class WeatherFetchResult {
  final DailyWeatherSummary? weather;
  final bool usedFallbackLocation;
  final String? message;

  const WeatherFetchResult({
    required this.weather,
    required this.usedFallbackLocation,
    this.message,
  });
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Position?> _tryPosition({bool highAccuracy = false}) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return null;
      }
      if (perm == LocationPermission.deniedForever) return null;
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      // 1) Position « last known » : instantanée si l'OS l'a déjà en cache.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          // On lance quand même un GPS frais en tâche de fond — sans bloquer.
          unawaited(_warmupCurrentPosition(highAccuracy));
          return last;
        }
      } catch (_) {}
      // 2) Sinon on tente un fix GPS, mais avec un timeout court.
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: highAccuracy
              ? LocationAccuracy.high
              : LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 6),
        ),
      ).timeout(const Duration(seconds: 7), onTimeout: () {
        throw TimeoutException('GPS timeout');
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> _warmupCurrentPosition(bool highAccuracy) async {
    try {
      await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: highAccuracy
              ? LocationAccuracy.high
              : LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 11));
    } catch (_) {}
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    // BigDataCloud reverse-geocoding gratuit, sans clé API.
    final uri = Uri.parse(
      'https://api.bigdatacloud.net/data/reverse-geocode-client'
      '?latitude=${lat.toStringAsFixed(4)}'
      '&longitude=${lon.toStringAsFixed(4)}'
      '&localityLanguage=fr',
    );
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return '';
      final j = json.decode(res.body) as Map<String, dynamic>;
      final city = (j['city'] as String?)?.trim();
      final locality = (j['locality'] as String?)?.trim();
      final principal = (j['principalSubdivision'] as String?)?.trim();
      if (city != null && city.isNotEmpty) return city;
      if (locality != null && locality.isNotEmpty) return locality;
      if (principal != null && principal.isNotEmpty) return principal;
    } catch (_) {}
    return '';
  }

  /// Récupère la météo complète (jour + horaire + courant) pour la position
  /// **actuelle**. Ne met aucun cache de position en cache : si l’utilisateur
  /// se déplace, le prochain appel renverra la météo de sa nouvelle zone.
  Future<WeatherFetchResult> fetchTodayForecast({
    bool highAccuracy = false,
  }) async {
    final pos = await _tryPosition(highAccuracy: highAccuracy);
    final lat = pos?.latitude ?? kWeatherFallbackLat;
    final lon = pos?.longitude ?? kWeatherFallbackLon;
    final usedFallback = pos == null;

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${lat.toStringAsFixed(4)}'
      '&longitude=${lon.toStringAsFixed(4)}'
      '&current=temperature_2m,apparent_temperature,weather_code,'
      'wind_speed_10m,relative_humidity_2m,is_day'
      '&hourly=temperature_2m,apparent_temperature,weather_code,'
      'precipitation,precipitation_probability,wind_speed_10m,is_day'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset'
      '&timezone=auto'
      '&forecast_days=1',
    );

    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        return WeatherFetchResult(
          weather: null,
          usedFallbackLocation: usedFallback,
          message: 'HTTP ${res.statusCode}',
        );
      }
      final j = json.decode(res.body) as Map<String, dynamic>;
      final daily = j['daily'] as Map<String, dynamic>?;
      if (daily == null) {
        return const WeatherFetchResult(
          weather: null,
          usedFallbackLocation: false,
          message: 'Réponse invalide',
        );
      }
      final times = (daily['time'] as List<dynamic>?) ?? [];
      final codes = (daily['weather_code'] as List<dynamic>?) ?? [];
      final tMax = (daily['temperature_2m_max'] as List<dynamic>?) ?? [];
      final tMin = (daily['temperature_2m_min'] as List<dynamic>?) ?? [];
      final sunrises = (daily['sunrise'] as List<dynamic>?) ?? const [];
      final sunsets = (daily['sunset'] as List<dynamic>?) ?? const [];
      if (times.isEmpty || codes.isEmpty || tMax.isEmpty || tMin.isEmpty) {
        return WeatherFetchResult(
          weather: null,
          usedFallbackLocation: usedFallback,
          message: 'Données incomplètes',
        );
      }

      final hourly = _parseHourly(j['hourly'] as Map<String, dynamic>?);
      final current = j['current'] as Map<String, dynamic>?;

      String city = '';
      if (!usedFallback) {
        city = await _reverseGeocode(lat, lon);
      } else {
        city = 'Paris';
      }

      final w = DailyWeatherSummary(
        latitude: lat,
        longitude: lon,
        date: DateTime.tryParse(times.first as String) ?? DateTime.now(),
        weatherCode: (codes.first as num).toInt(),
        tempMax: (tMax.first as num).toDouble(),
        tempMin: (tMin.first as num).toDouble(),
        cityName: city,
        sunrise: sunrises.isNotEmpty
            ? DateTime.tryParse(sunrises.first as String)
            : null,
        sunset: sunsets.isNotEmpty
            ? DateTime.tryParse(sunsets.first as String)
            : null,
        currentTemperatureC: _readNum(current?['temperature_2m']),
        currentApparentTemperatureC: _readNum(current?['apparent_temperature']),
        currentWeatherCode: _readInt(current?['weather_code']),
        currentWindSpeedKmh: _readNum(current?['wind_speed_10m']),
        currentRelativeHumidityPct: _readInt(current?['relative_humidity_2m']),
        currentIsDay: _readBool(current?['is_day']),
        hourly: hourly,
        fetchedAt: DateTime.now(),
      );
      return WeatherFetchResult(
        weather: w,
        usedFallbackLocation: usedFallback,
        message: usedFallback ? 'Paris (approx.)' : null,
      );
    } catch (e) {
      return WeatherFetchResult(
        weather: null,
        usedFallbackLocation: usedFallback,
        message: '$e',
      );
    }
  }

  List<HourlyWeatherPoint> _parseHourly(Map<String, dynamic>? hourly) {
    if (hourly == null) return const [];
    final times = (hourly['time'] as List<dynamic>?) ?? const [];
    final temps = (hourly['temperature_2m'] as List<dynamic>?) ?? const [];
    final apparents =
        (hourly['apparent_temperature'] as List<dynamic>?) ?? const [];
    final codes = (hourly['weather_code'] as List<dynamic>?) ?? const [];
    final precips = (hourly['precipitation'] as List<dynamic>?) ?? const [];
    final probas =
        (hourly['precipitation_probability'] as List<dynamic>?) ?? const [];
    final winds = (hourly['wind_speed_10m'] as List<dynamic>?) ?? const [];
    final isDays = (hourly['is_day'] as List<dynamic>?) ?? const [];

    final out = <HourlyWeatherPoint>[];
    for (var i = 0; i < times.length; i++) {
      final t = DateTime.tryParse(times[i] as String);
      if (t == null) continue;
      out.add(HourlyWeatherPoint(
        time: t,
        temperatureC: _readNum(_at(temps, i)) ?? 0,
        apparentTemperatureC: _readNum(_at(apparents, i)) ?? 0,
        weatherCode: _readInt(_at(codes, i)) ?? 0,
        precipitationProbabilityPct: _readInt(_at(probas, i)) ?? 0,
        precipitationMm: _readNum(_at(precips, i)) ?? 0,
        windSpeedKmh: _readNum(_at(winds, i)) ?? 0,
        isDay: _readBool(_at(isDays, i)) ?? true,
      ));
    }
    return out;
  }

  static dynamic _at(List<dynamic> list, int i) =>
      (i >= 0 && i < list.length) ? list[i] : null;

  static double? _readNum(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _readInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    if (v is bool) return v ? 1 : 0;
    return null;
  }

  static bool? _readBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return null;
  }
}
