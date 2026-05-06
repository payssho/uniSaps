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

  Future<Position?> _tryPosition() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return null;
    }
    if (perm == LocationPermission.deniedForever) return null;
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    return Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.medium),
    );
  }

  Future<WeatherFetchResult> fetchTodayForecast() async {
    final pos = await _tryPosition();
    final lat = pos?.latitude ?? kWeatherFallbackLat;
    final lon = pos?.longitude ?? kWeatherFallbackLon;
    final usedFallback = pos == null;

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${lat.toStringAsFixed(4)}'
      '&longitude=${lon.toStringAsFixed(4)}'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min'
      '&timezone=auto'
      '&forecast_days=1',
    );

    try {
      final res = await _client.get(uri);
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
      if (times.isEmpty || codes.isEmpty || tMax.isEmpty || tMin.isEmpty) {
        return WeatherFetchResult(
          weather: null,
          usedFallbackLocation: usedFallback,
          message: 'Données incomplètes',
        );
      }
      final w = DailyWeatherSummary(
        latitude: lat,
        longitude: lon,
        date: DateTime.tryParse(times.first as String) ?? DateTime.now(),
        weatherCode: (codes.first as num).toInt(),
        tempMax: (tMax.first as num).toDouble(),
        tempMin: (tMin.first as num).toDouble(),
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
}
