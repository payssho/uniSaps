import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/garment_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final garmentsProvider = StreamProvider.family<List<GarmentModel>, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).garmentsStream(uid);
});

final garmentsByCategoryProvider =
    StreamProvider.family<List<GarmentModel>, ({String uid, String category})>((ref, params) {
  return ref.watch(firestoreServiceProvider).garmentsStream(
    params.uid,
    category: params.category,
  );
});

class GarmentNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _db;
  final StorageService _storage;

  GarmentNotifier(this._db, this._storage) : super(const AsyncValue.data(null));

  Future<bool> addGarment({
    required String userId,
    required String name,
    required String brand,
    required String color,
    required String category,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    state = const AsyncValue.loading();
    try {
      String imageUrl = '';
      if (imageBytes != null && imageName != null) {
        imageUrl = await _storage.uploadGarmentImageBytes(imageBytes, userId, imageName);
      }
      final garment = GarmentModel(
        userId: userId,
        name: name,
        brand: brand,
        color: color,
        category: category,
        imageUrl: imageUrl,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _db.addGarment(garment);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteGarment(String uid, String garmentId) async {
    try {
      await _db.deleteGarment(uid, garmentId);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final garmentNotifierProvider = StateNotifierProvider<GarmentNotifier, AsyncValue<void>>((ref) {
  return GarmentNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(storageServiceProvider),
  );
});
