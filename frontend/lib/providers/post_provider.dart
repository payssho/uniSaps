import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import 'garment_provider.dart';

final postsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(firestoreServiceProvider).postsStream();
});

class PostNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _db;
  final StorageService _storage;

  PostNotifier(this._db, this._storage) : super(const AsyncValue.data(null));

  Future<bool> createPost({
    required String userId,
    required String username,
    required String userPhotoUrl,
    required Uint8List imageBytes,
    required String imageName,
    String caption = '',
    String outfitId = '',
    List<GarmentRef> garmentRefs = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final imageUrl = await _storage.uploadPostImageBytes(imageBytes, userId, imageName);
      final post = PostModel(
        userId: userId,
        username: username,
        userPhotoUrl: userPhotoUrl,
        imageUrl: imageUrl,
        outfitId: outfitId,
        garmentRefs: garmentRefs,
        caption: caption,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _db.addPost(post);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<void> toggleLike(String postId, String uid) async {
    await _db.toggleLike(postId, uid);
  }

  Future<void> deletePost(String postId) async {
    await _db.deletePost(postId);
  }
}

final postNotifierProvider = StateNotifierProvider<PostNotifier, AsyncValue<void>>((ref) {
  return PostNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(storageServiceProvider),
  );
});
