import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/outfit_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/friendship_provider.dart';
import '../providers/garment_provider.dart';
import '../providers/outfit_provider.dart';
import '../providers/post_provider.dart';
import '../core/constants/weather_catalog.dart';
import '../providers/weather_provider.dart';
import 'firebase_storage_display_url.dart';
import 'widget_constants.dart';

/// Service de synchronisation des données vers les widgets Android.
class WidgetSyncService {
  WidgetSyncService._();

  static bool _initialized = false;

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

  static PostModel? _latestFriendPost(
    List<PostModel> posts,
    UserModel user,
  ) {
    final friendSet = {...user.friends};
    final filtered = posts
        .where((p) => friendSet.contains(p.userId) && p.userId != user.uid)
        .toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) {
      final da = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
      final db = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
      return db.compareTo(da);
    });
    return filtered.first;
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
    final posts = ref.read(postsProvider).valueOrNull ?? [];
    final friendsPosts = ref.read(friendsPostsProvider).valueOrNull ?? [];
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

    String dailyPhotoPath = '';
    if (user != null && user.dailyPhotoUrl.isNotEmpty) {
      dailyPhotoPath = await _cacheImage(
        user.dailyPhotoUrl,
        'daily_photo_${user.uid}',
      );
    } else if (dailyOutfit != null && dailyOutfit.referencePhotoUrl.isNotEmpty) {
      dailyPhotoPath = await _cacheImage(
        dailyOutfit.referencePhotoUrl,
        'daily_ref_${dailyOutfit.id}',
      );
    }

    final thumbPaths = <String>[];
    if (dailyOutfit != null) {
      var i = 0;
      for (final gid in dailyOutfit.garmentIds.take(4)) {
        final g = garmentById[gid];
        if (g == null || g.imageUrl.isEmpty) continue;
        final p = await _cacheImage(g.imageUrl, 'garment_${gid}_$i');
        if (p.isNotEmpty) thumbPaths.add(p);
        i++;
      }
    }

    final todayCtx = ref.read(todayOutfitContextProvider);
    final suitableCount =
        outfits.where((o) => todayCtx.isGoodPick(o)).length;

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
        weatherLabel = WeatherTagKeys.visualFor(tags).shortLabel;
      }
    });

    var inspiPath = '';
    var inspiUsername = '';
    var inspiHasContent = false;
    if (user != null) {
      final inspiPost = _latestFriendPost(friendsPosts.isNotEmpty ? friendsPosts : posts, user);
      if (inspiPost != null) {
        inspiPath = await _cacheImage(
          inspiPost.imageUrl,
          'inspi_${inspiPost.id}',
        );
        inspiUsername = '@${inspiPost.username}';
        inspiHasContent = inspiPath.isNotEmpty;
      }
    }

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
      WidgetDataKeys.dailyPhotoPath,
      dailyPhotoPath,
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.garmentThumbPaths,
      thumbPaths.join('|'),
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
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.inspiImagePath,
      inspiPath,
    );
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.inspiUsername,
      inspiUsername,
    );
    await HomeWidget.saveWidgetData<bool>(
      WidgetDataKeys.inspiHasContent,
      inspiHasContent,
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
    await HomeWidget.saveWidgetData<String>(WidgetDataKeys.dailyPhotoPath, '');
    await HomeWidget.saveWidgetData<String>(
      WidgetDataKeys.garmentThumbPaths,
      '',
    );
    await HomeWidget.saveWidgetData<bool>(WidgetDataKeys.inspiHasContent, false);
    await _updateAllWidgets();
  }

  static const _qualifiedProviders = [
    'com.unisaps.app.widgets.DailyOutfitWidgetProvider',
    'com.unisaps.app.widgets.PickOutfitWidgetProvider',
    'com.unisaps.app.widgets.InspiWidgetProvider',
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
