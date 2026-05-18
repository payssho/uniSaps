import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/garment_model.dart';
import '../models/outfit_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import 'garment_provider.dart';

final creatorPostsProvider = StreamProvider.family<List<PostModel>, String>(
  (ref, uid) {
    if (uid.isEmpty) return Stream.value([]);
    return ref.watch(firestoreServiceProvider).creatorPostsStream(uid);
  },
);

class CreatorPostNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _db;
  final StorageService _storage;

  CreatorPostNotifier(this._db, this._storage)
      : super(const AsyncValue.data(null));

  Future<bool> createSponsoredPost({
    required UserModel brand,
    required OutfitModel outfit,
    required List<GarmentModel> garments,
    required Uint8List previewBytes,
    required String previewFileName,
    required String collectionId,
    required bool isActive,
    String caption = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final previewUrl = await _storage.uploadPostImageBytes(
        previewBytes,
        brand.uid,
        previewFileName,
      );
      final refs = garments
          .map((g) => GarmentRef(name: g.name, brand: g.brand))
          .toList();
      final post = PostModel(
        userId: brand.uid,
        username: brand.username.isNotEmpty ? brand.username : brand.displayName,
        userPhotoUrl: brand.creatorLogoUrl.isNotEmpty
            ? brand.creatorLogoUrl
            : brand.profilePhotoUrl,
        imageUrl: previewUrl,
        previewImageUrl: previewUrl,
        outfitId: outfit.id,
        garmentRefs: refs,
        caption: caption,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        postKind: 'sponsored',
        isSponsored: true,
        isActive: isActive,
        collectionId: collectionId,
      );
      await _db.addPost(post);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<void> setPostActive(String postId, bool active) async {
    await _db.updatePost(postId, {'is_active': active});
  }

  Future<void> deletePost(String postId) async {
    await _db.deletePost(postId);
  }
}

final creatorPostNotifierProvider =
    StateNotifierProvider<CreatorPostNotifier, AsyncValue<void>>((ref) {
  return CreatorPostNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(storageServiceProvider),
  );
});
