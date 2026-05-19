import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/garment_model.dart';
import '../models/collection_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'garment_provider.dart';

final collectionsProvider = StreamProvider.family<List<CollectionModel>, String>(
  (ref, uid) {
    if (uid.isEmpty) return Stream.value([]);
    return ref.watch(firestoreServiceProvider).collectionsStream(uid);
  },
);

/// Vêtements groupés par `collection_id` (clé vide = sans collection).
final garmentsByCollectionProvider =
    Provider.family<Map<String, List<GarmentModel>>, String>((ref, uid) {
  final garments = ref.watch(garmentsProvider(uid)).valueOrNull ?? [];
  final grouped = <String, List<GarmentModel>>{};
  for (final g in garments) {
    grouped.putIfAbsent(g.collectionId, () => []).add(g);
  }
  return grouped;
});

class CollectionNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _db;
  final GarmentNotifier Function() _garmentNotifier;

  CollectionNotifier(this._db, this._garmentNotifier)
      : super(const AsyncValue.data(null));

  Future<String?> createCollection({
    required String userId,
    required String name,
    required String startDate,
    required String endDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final model = CollectionModel(
        userId: userId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now().toIso8601String(),
      );
      final id = await _db.addCollection(model);
      state = const AsyncValue.data(null);
      return id;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return null;
    }
  }

  /// Supprime tous les vêtements de la collection puis le document collection.
  Future<bool> deleteCollection({
    required String uid,
    required String collectionId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final garments = await _db.getGarmentsByCollectionId(uid, collectionId);
      final notifier = _garmentNotifier();
      for (final g in garments) {
        await notifier.deleteGarment(uid, g.id);
      }
      await _db.deleteCollectionDocument(uid, collectionId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }
}

final collectionNotifierProvider =
    StateNotifierProvider<CollectionNotifier, AsyncValue<void>>((ref) {
  return CollectionNotifier(
    ref.watch(firestoreServiceProvider),
    () => ref.read(garmentNotifierProvider.notifier),
  );
});
