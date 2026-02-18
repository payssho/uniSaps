import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/outfit_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

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
  }) async {
    state = const AsyncValue.loading();
    try {
      final outfit = OutfitModel(
        userId: userId,
        name: name,
        garments: garments,
        createdAt: DateTime.now().toIso8601String(),
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
    await _db.updateUser(uid, {
      'daily_outfit_id': outfitId,
      'daily_outfit_date': today,
    });
    await _db.updateOutfit(uid, outfitId, {
      'times_worn': FieldValue.increment(1),
      'last_worn': today,
    });
  }

  Future<void> setDailyPhoto(String uid, String photoUrl) async {
    await _db.updateUser(uid, {'daily_photo_url': photoUrl});
  }

  Future<void> clearDailyOutfit(String uid) async {
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
