import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collection_model.dart';
import '../models/garment_model.dart';
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

  CollectionNotifier(this._db) : super(const AsyncValue.data(null));

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
}

final collectionNotifierProvider =
    StateNotifierProvider<CollectionNotifier, AsyncValue<void>>((ref) {
  return CollectionNotifier(ref.watch(firestoreServiceProvider));
});
