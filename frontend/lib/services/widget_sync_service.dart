import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/outfit_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/garment_provider.dart';
import '../providers/outfit_provider.dart';
import '../providers/post_provider.dart';
import '../core/constants/weather_catalog.dart';
import '../providers/weather_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/domain_l10n.dart';
import '../l10n/generated/app_localizations.dart';
import 'firebase_storage_display_url.dart';
import 'widget_constants.dart';

/// Service de synchronisation des données vers les widgets Android.
class WidgetSyncService {
  WidgetSyncService._();

  static bool _initialized = false;

  static const int _carouselMaxItems = 12;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (!Platform.isAndroid) return;
    await HomeWidget.setAppGroupId('group.com.unisaps.widget');
    _initialized = true;
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static bool _hasChosenOutfitToday(UserModel? user) {
    if (user == null) return false;
    return user.dailyOutfitId.isNotEmpty && user.dailyOutfitDate == _todayKey();
  }

  static String _sanitizeCarouselLabel(String s) {
    return s.replaceAll('|', ' ').trim();
  }

  static Future<String> _cacheImage(String url, String fileName) async {
    if (url.isEmpty) return '';
    try {
      final downloadUrl = await resolveFirebaseStorageDisplayUrl(url);
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/widget_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      final safeName = fileName.replaceAll(RegExp(r'[^\w\-.]'), '_');
      final file = File('${cacheDir.path}/$safeName');
      if (await file.exists() && await file.length() > 0) {
        return file.path;
      }
      final res = await http.get(Uri.parse(downloadUrl)).timeout(
            const Duration(seconds: 15),
          );
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(res.bodyBytes);
        return file.path;
      }
    } catch (e) {
      debugPrint('WidgetSyncService: cache image failed ($fileName): $e');
    }
    return '';
  }

  static Future<void> sync(WidgetRef ref) async {
    if (!Platform.isAndroid) return;
    await _ensureInitialized();

    final uid = ref.read(authServiceProvider).uid;
    if (uid.isEmpty) {
      await _clearWidgetData();
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    final outfits = ref.read(outfitsProvider(uid)).valueOrNull ?? [];
    final garments = ref.read(garmentsProvider(uid)).valueOrNull ?? [];
    final hasPostedToday = ref.read(hasPostedTodayProvider);

    final hasChosen = _hasChosenOutfitToday(user);
    OutfitModel? dailyOutfit;
    if (hasChosen && user != null) {
      for (final o in outfits) {
        if (o.id == user.dailyOutfitId) {
          dailyOutfit = o;
          break;
        }
      }
    }

    final garmentById = {for (final g in garments) g.id: g};

    final outfitPaths = <String>[];
    final outfitNames = <String>[];
    for (final o in outfits.take(_carouselMaxItems)) {
      String? url;
      if (o.referencePhotoUrl.isNotEmpty) {
        url = o.referencePhotoUrl;
      } else {
        for (final gid in o.garmentIds) {
          final g = garmentById[gid];
          if (g != null && g.imageUrl.isNotEmpty) {
            url = g.imageUrl;
            break;
          }
        }
      }
      if (url == null || url.isEmpty) continue;
      final p = await _cacheImage(url, 'wc_${o.id}');
      if (p.isEmpty) continue;
      outfitPaths.add(p);
      outfitNames.add(_sanitizeCarouselLabel(
          o.name.isEmpty ? 'Tenue' : o.name));
    }

    final garmentPaths = <String>[];
    final garmentNames = <String>[];
    for (final g in garments.take(_carouselMaxItems)) {
      if (g.imageUrl.isEmpty) continue;
      final p = await _cacheImage(g.imageUrl, 'gc_${g.id}');
      if (p.isEmpty) continue;
      garmentPaths.add(p);
      garmentNames.add(_sanitizeCarouselLabel(
          g.name.isEmpty ? 'Pièce' : g.name));
    }

    final todayCtx = ref.read(todayOutfitContextProvider);
    final suitableCount =
        outfits.where((o) => todayCtx.isGoodPick(o)).length;

    final suitablePickPaths = <String>[];
    final suitablePickNames = <String>[];
    for (final o
        in outfits.where((x) => todayCtx.isGoodPick(x)).take(_carouselMaxItems)) {
      String? url;
      if (o.referencePhotoUrl.isNotEmpty) {
        url = o.referencePhotoUrl;
      } else {
        for (final gid in o.garmentIds) {
          final g = garmentById[gid];
          if (g != null && g.imageUrl.isNotEmpty) {
            url = g.imageUrl;
            break;
          }
        }
      }
      if (url == null || url.isEmpty) continue;
      final p = await _cacheImage(url, 'sp_${o.id}');
      if (p.isEmpty) continue;
      suitablePickPaths.add(p);
      suitablePickNames.add(_sanitizeCarouselLabel(
          o.name.isEmpty ? 'Tenue' : o.name));
    }

    var weatherTemp = '';
    var weatherLabel = '';
    final weatherResult = ref.read(todayWeatherFetchProvider);
    weatherResult.whenData((r) {
      final w = r.weather;
      if (w != null) {
        final t = w.currentTemperatureC ?? ((w.tempMin + w.tempMax) / 2);
        weatherTemp = '${t.round()}°';
        final tags = WeatherTagKeys.dayContext(
          weatherCode: w.weatherCode,
          tempMin: w.tempMin,
          tempMax: w.tempMax,
        );
        final locale = ref.read(localeProvider).locale;
        final l10n = lookupAppLocalizations(locale);
        weatherLabel = weatherVisualShortLabelL10n(l10n, tags);
      }
    });

    await HomeWidget.saveWidgetData<String>(WidgetDataKeys.authUid, uid);
    await HomeWidget.saveWidgetData<bool>(
      WidgetDataKeys.hasChosenOutfitToday,
      hasChosen,
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.dailyOutfitId,
      dailyOutfit?.id ?? '',
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.dailyOutfitName,
      dailyOutfit?.name ?? '',
    );
    await HomeWidget.saveWidgetData<int>(
      WidgetDataKeys.currentStreak,
      user?.currentStreak ?? 0,
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.outfitCarouselPaths,
      outfitPaths.join('|'),
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.outfitCarouselNames,
      outfitNames.join('|'),
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.garmentCarouselPaths,
      garmentPaths.join('|'),
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.garmentCarouselNames,
      garmentNames.join('|'),
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.suitablePickCarouselPaths,
      suitablePickPaths.join('|'),
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.suitablePickCarouselNames,
      suitablePickNames.join('|'),
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.weatherTemp,
      weatherTemp,
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.weatherLabel,
      weatherLabel,
    );
    await HomeWidget.saveWidgetData<int>(
      WidgetDataKeys.suitableOutfitsCount,
      suitableCount,
    );
    await HomeWidget.saveWidgetData<bool>(
      WidgetDataKeys.hasPostedToday,
      hasPostedToday,
    );

    await _updateAllWidgets();
  }

  static Future<void> _clearWidgetData() async {
    await HomeWidget.saveWidgetData<String>(WidgetDataKeys.authUid, '');
    await HomeWidget.saveWidgetData<bool>(
      WidgetDataKeys.hasChosenOutfitToday,
      false,
    );
    await HomeWidget.saveWidgetData<String>(WidgetDataKeys.dailyOutfitName, '');
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.outfitCarouselPaths,
      '',
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.outfitCarouselNames,
      '',
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.garmentCarouselPaths,
      '',
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.garmentCarouselNames,
      '',
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.suitablePickCarouselPaths,
      '',
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.suitablePickCarouselNames,
      '',
    );
    await HomeWidget.saveWidgetData<String>(WidgetDataKeys.weatherTemp, '');
    await HomeWidget.saveWidgetData<String>(WidgetDataKeys.weatherLabel, '');
    await HomeWidget.saveWidgetData<int>(WidgetDataKeys.suitableOutfitsCount, 0);
    await _updateAllWidgets();
  }

  static const _qualifiedProviders = [
    'com.unisaps.app.widgets.OutfitCarouselWidgetProvider',
    'com.unisaps.app.widgets.DressingCarouselWidgetProvider',
    'com.unisaps.app.widgets.TodayPickWidgetProvider',
  ];

  static Future<void> _updateAllWidgets() async {
    for (final qualified in _qualifiedProviders) {
      try {
        await HomeWidget.updateWidget(qualifiedAndroidName: qualified);
      } catch (e) {
        debugPrint('WidgetSyncService: update $qualified failed: $e');
      }
    }
  }
}
