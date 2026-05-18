import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/garment_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final apiServiceProvider = Provider<ApiService>((ref) {
  // URL de base pour l'API backend
  // Local dev :
  //   - Web (Chrome):     http://localhost:8000/api/v1
  //   - Émulateur Android: http://10.0.2.2:8000/api/v1
  // Production (Vercel):
  //   - https://unisaps.vercel.app/api/v1
  const baseUrl = kIsWeb
      ? 'http://localhost:8000/api/v1'
      : 'https://unisaps.vercel.app/api/v1';
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
    required List<String> colors,
    required String category,
    List<String> styleTags = const [],
    String formality = '',
    String season = '',
    String pattern = '',
    String material = '',
    List<Uint8List> imageBytesList = const [],
    List<String> imageNames = const [],
    bool removeBackground = true,
    String collectionId = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final urls = <String>[];
      if (imageBytesList.isNotEmpty) {
        if (imageBytesList.length != imageNames.length) {
          throw Exception('Incohérence images / noms de fichiers.');
        }
        for (var i = 0; i < imageBytesList.length; i++) {
          final u = await _apiService.uploadImage(
            imageBytes: imageBytesList[i],
            filename: imageNames[i],
            folder: 'garments',
            removeBackground: removeBackground,
          );
          if (u.isEmpty) {
            throw Exception('L\'URL d\'une image est vide après l\'upload');
          }
          urls.add(u);
        }
      }
      final garment = GarmentModel(
        userId: userId,
        name: name,
        brand: brand,
        colors: colors,
        category: category,
        imageUrls: urls,
        createdAt: DateTime.now().toIso8601String(),
        styleTags: styleTags,
        formality: formality,
        season: season,
        pattern: pattern,
        material: material,
        collectionId: collectionId,
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
    required List<String> colors,
    required String category,
    /// URLs déjà en ligne conservées par l’utilisateur (ordre final).
    List<String> keptImageUrls = const [],
    List<Uint8List> newImageBytesList = const [],
    List<String> newImageNames = const [],
    bool removeBackground = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final existingGarment = await _db.getGarment(uid, garmentId);
      if (existingGarment == null) {
        state = AsyncValue.error('Vêtement introuvable', StackTrace.current);
        return false;
      }

      if (newImageBytesList.isNotEmpty &&
          newImageBytesList.length != newImageNames.length) {
        throw Exception('Incohérence nouvelles images / noms de fichiers.');
      }

      final previousUrls = existingGarment.imageUrls.isNotEmpty
          ? existingGarment.imageUrls
          : (existingGarment.imageUrl.isNotEmpty
              ? [existingGarment.imageUrl]
              : <String>[]);

      // Supprimer du storage les photos retirées par l’utilisateur
      for (final url in previousUrls) {
        if (!keptImageUrls.contains(url)) {
          await _storage.deleteImage(url);
        }
      }

      final uploaded = <String>[];
      for (var i = 0; i < newImageBytesList.length; i++) {
        final u = await _apiService.uploadImage(
          imageBytes: newImageBytesList[i],
          filename: newImageNames[i],
          folder: 'garments',
          removeBackground: removeBackground,
        );
        if (u.isNotEmpty) uploaded.add(u);
      }

      final finalUrls = [...keptImageUrls, ...uploaded];

      final garment = GarmentModel(
        id: garmentId,
        userId: uid,
        name: name,
        brand: brand,
        colors: colors,
        category: category,
        imageUrls: finalUrls,
        createdAt: existingGarment.createdAt,
        timesWorn: existingGarment.timesWorn,
        styleTags: existingGarment.styleTags,
        formality: existingGarment.formality,
        season: existingGarment.season,
        pattern: existingGarment.pattern,
        material: existingGarment.material,
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
      if (garment != null) {
        final urls = garment.imageUrls.isNotEmpty
            ? garment.imageUrls
            : (garment.imageUrl.isNotEmpty ? [garment.imageUrl] : <String>[]);
        for (final url in urls) {
          if (url.isNotEmpty) await _storage.deleteImage(url);
        }
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
