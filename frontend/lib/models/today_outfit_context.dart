import '../core/constants/weather_catalog.dart';
import '../models/daily_weather_summary.dart';
import '../models/outfit_model.dart';

class TodayOutfitContext {
  /// Tags dérivés météo (vide si données indisponibles).
  final Set<String> activeWeatherTags;
  final String seasonKey;
  final bool weatherDataAvailable;

  const TodayOutfitContext({
    required this.activeWeatherTags,
    required this.seasonKey,
    required this.weatherDataAvailable,
  });

  factory TodayOutfitContext.fromWeather(DailyWeatherSummary w) {
    final tags = WeatherTagKeys.dayContext(
      weatherCode: w.weatherCode,
      tempMin: w.tempMin,
      tempMax: w.tempMax,
    );
    return TodayOutfitContext(
      activeWeatherTags: tags,
      seasonKey: SeasonKeys.forLocalDate(w.date),
      weatherDataAvailable: true,
    );
  }

  factory TodayOutfitContext.seasonOnly() {
    return TodayOutfitContext(
      activeWeatherTags: {},
      seasonKey: SeasonKeys.forLocalDate(DateTime.now()),
      weatherDataAvailable: false,
    );
  }

  List<OutfitModel> sortOutfits(List<OutfitModel> outfits) {
    bool m(OutfitModel o) {
      final seasonOk = o.seasons.isEmpty || o.seasons.contains(seasonKey);
      if (!weatherDataAvailable) return seasonOk;
      final weatherOk = o.weatherTags.isEmpty ||
          o.weatherTags.any((t) => activeWeatherTags.contains(t));
      return seasonOk && weatherOk;
    }

    final yes = outfits.where(m).toList();
    final no = outfits.where((o) => !m(o)).toList();
    return [...yes, ...no];
  }

  bool isGoodPick(OutfitModel o) {
    final seasonOk = o.seasons.isEmpty || o.seasons.contains(seasonKey);
    if (!weatherDataAvailable) return seasonOk;
    final weatherOk = o.weatherTags.isEmpty ||
        o.weatherTags.any((t) => activeWeatherTags.contains(t));
    return seasonOk && weatherOk;
  }
}
