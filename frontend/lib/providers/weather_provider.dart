import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/today_outfit_context.dart';
import '../services/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final todayWeatherFetchProvider =
    FutureProvider.autoDispose<WeatherFetchResult>((ref) async {
  return ref.read(weatherServiceProvider).fetchTodayForecast();
});

/// Contexte saison + météo pour tri / suggestions (saison seule si pas d’API).
final todayOutfitContextProvider = Provider<TodayOutfitContext>((ref) {
  return ref.watch(todayWeatherFetchProvider).when(
        data: (r) {
          final w = r.weather;
          if (w != null) return TodayOutfitContext.fromWeather(w);
          return TodayOutfitContext.seasonOnly();
        },
        loading: TodayOutfitContext.seasonOnly,
        error: (_, __) => TodayOutfitContext.seasonOnly(),
      );
});
