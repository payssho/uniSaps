import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/garment_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final apiServiceProvider = Provider<ApiService>((ref) {
  // URL de base pour l'API backend
  // Pour émulateur Android: http://10.0.2.2:8000/api/v1
  // Pour appareil physique: http://<IP_LOCAL>:8000/api/v1
  // Pour production: https://votre-domaine.com/api/v1
  const baseUrl = 'http://10.0.2.2:8000/api/v1';
  return ApiService(
    baseUrl: baseUrl,
    authService: ref.watch(authServiceProvider),
  );
});

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
  final ApiService _apiService;

  GarmentNotifier(this._db, this._storage, this._apiService) : super(const AsyncValue.data(null));

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
        // Utiliser l'API backend pour l'upload des images de vêtements
        // Le backend supprimera automatiquement le background via rembg
        imageUrl = await _apiService.uploadImage(
          imageBytes: imageBytes,
          filename: imageName,
          folder: 'garments',
        );
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

  Future<bool> updateGarment({
    required String uid,
    required String garmentId,
    required String name,
    required String brand,
    required String color,
    required String category,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Récupérer le vêtement existant
      final existingGarment = await _db.getGarment(uid, garmentId);
      if (existingGarment == null) {
        state = AsyncValue.error('Vêtement introuvable', StackTrace.current);
        return false;
      }

      String imageUrl = existingGarment.imageUrl;
      
      // Si une nouvelle image est fournie, uploader et supprimer l'ancienne
      if (imageBytes != null && imageName != null) {
        final newImageUrl = await _apiService.uploadImage(
          imageBytes: imageBytes,
          filename: imageName,
          folder: 'garments',
        );
        // Supprimer l'ancienne image si elle existe
        if (imageUrl.isNotEmpty) {
          await _storage.deleteImage(imageUrl);
        }
        imageUrl = newImageUrl;
      }

      final garment = GarmentModel(
        id: garmentId,
        userId: uid,
        name: name,
        brand: brand,
        color: color,
        category: category,
        imageUrl: imageUrl,
        createdAt: existingGarment.createdAt,
        timesWorn: existingGarment.timesWorn,
      );
      
      await _db.updateGarment(uid, garmentId, garment.toMap());
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteGarment(String uid, String garmentId) async {
    try {
      // Récupérer le vêtement pour supprimer son image
      final garment = await _db.getGarment(uid, garmentId);
      if (garment != null && garment.imageUrl.isNotEmpty) {
        await _storage.deleteImage(garment.imageUrl);
      }
      // Supprimer le document Firestore
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
    ref.watch(apiServiceProvider),
  );
});
