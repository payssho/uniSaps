import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/outfit_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// Indique si l'onglet Outfits est actuellement en mode "Swipe" (true) ou Biblio (false).
final outfitsIsSwipeModeProvider = StateProvider<bool>((ref) => false);

final outfitsProvider = StreamProvider.family<List<OutfitModel>, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).outfitsStream(uid);
});

class OutfitNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _db;

  OutfitNotifier(this._db) : super(const AsyncValue.data(null));

  Future<String?> createOutfit({
    required String userId,
    required String name,
    required Map<String, String> garments,
    String referencePhotoUrl = '',
    List<String> seasons = const [],
    List<String> weatherTags = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final outfit = OutfitModel(
        userId: userId,
        name: name,
        garments: garments,
        createdAt: DateTime.now().toIso8601String(),
        referencePhotoUrl: referencePhotoUrl,
        seasons: seasons,
        weatherTags: weatherTags,
      );
      final id = await _db.addOutfit(outfit);
      state = const AsyncValue.data(null);
      return id;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return null;
    }
  }

  Future<void> setDailyOutfit(String uid, String outfitId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final user = await _db.getUser(uid);
    if (user == null) return;

    final prevId = user.dailyOutfitId;
    final prevDate = user.dailyOutfitDate;

    // Déjà l’outfit du jour : ne pas recompter plusieurs « ports » dans la même journée.
    if (prevId == outfitId && prevDate == today) {
      return;
    }

    final sameDayPrevious =
        prevDate == today && prevId.isNotEmpty && prevId != outfitId;

    if (sameDayPrevious) {
      final prevOutfit = await _db.getOutfit(uid, prevId);
      if (prevOutfit != null) {
        final next = (prevOutfit.timesWorn - 1).clamp(0, 0x7fffffff);
        await _db.updateOutfit(uid, prevId, {
          'times_worn': next,
        });
      }
    }

    await _db.updateUser(uid, {
      'daily_outfit_id': outfitId,
      'daily_outfit_date': today,
    });
    await _db.updateOutfit(uid, outfitId, {
      'times_worn': FieldValue.increment(1),
      'last_worn': today,
    });
  }

  Future<void> setDailyPhoto(String uid, String outfitId, String photoUrl) async {
    // On remplace uniquement la photo du JOUR courant.
    // Si une photo existe déjà pour aujourd'hui, on la retire de l'ancien outfit.
    final user = await _db.getUser(uid);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (user != null) {
      final lastDate = user.dailyOutfitDate;
      final prevPhoto = user.dailyPhotoUrl;
      final prevOutfitId = user.dailyOutfitId;

      final isSameDay = lastDate == today;
      final hasPrevPhoto = prevPhoto.isNotEmpty && prevOutfitId.isNotEmpty;

      if (isSameDay && hasPrevPhoto) {
        // On enlève l'ancienne photo de l'ancien outfit pour ce jour.
        await _db.updateOutfit(uid, prevOutfitId, {
          'photo_urls': FieldValue.arrayRemove([prevPhoto]),
        });
      }
    }

    // On met à jour la photo du jour de l'utilisateur.
    await _db.updateUser(uid, {'daily_photo_url': photoUrl});

    // On ajoute la nouvelle photo à la liste des memories de l'outfit courant.
    await _db.updateOutfit(uid, outfitId, {
      'photo_urls': FieldValue.arrayUnion([photoUrl]),
    });
  }

  Future<void> clearDailyOutfit(String uid) async {
    final user = await _db.getUser(uid);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final hadToday = user != null &&
        user.dailyOutfitDate == today &&
        user.dailyOutfitId.isNotEmpty;
    final clearedId = user?.dailyOutfitId ?? '';

    if (hadToday) {
      final cur = await _db.getOutfit(uid, clearedId);
      if (cur != null) {
        final next = (cur.timesWorn - 1).clamp(0, 0x7fffffff);
        await _db.updateOutfit(uid, clearedId, {
          'times_worn': next,
        });
      }
    }

    await _db.updateUser(uid, {
      'daily_outfit_id': '',
      'daily_photo_url': '',
    });
  }

  Future<void> deleteOutfit(String uid, String outfitId) async {
    await _db.deleteOutfit(uid, outfitId);
  }
}

final outfitNotifierProvider = StateNotifierProvider<OutfitNotifier, AsyncValue<void>>((ref) {
  return OutfitNotifier(ref.watch(firestoreServiceProvider));
});
