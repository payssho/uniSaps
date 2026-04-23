import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/outfit_model.dart';
import '../models/garment_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import 'garment_provider.dart';

final postsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(firestoreServiceProvider).postsStream();
});

/// True si l'utilisateur courant a déjà posté aujourd'hui.
final hasPostedTodayProvider = Provider<bool>((ref) {
  final uid = ref.watch(authServiceProvider).uid;
  if (uid.isEmpty) return false;
  final posts = ref.watch(postsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  return posts.any((p) {
    if (p.userId != uid) return false;
    final dt = DateTime.tryParse(p.createdAt)?.toLocal();
    if (dt == null) return false;
    return dt.isAfter(todayStart) && dt.isBefore(todayEnd);
  });
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

  /// Crée un post à partir de la photo du jour + outfit du jour.
  /// Retourne 'already_posted' si l'utilisateur a déjà posté aujourd'hui.
  Future<String> createPostFromDaily({
    required UserModel user,
    required OutfitModel outfit,
    required List<GarmentModel> garments,
    String caption = '',
  }) async {
    if (user.dailyPhotoUrl.isEmpty) {
      state = AsyncValue.error('Aucune photo du jour.', StackTrace.current);
      return 'no_photo';
    }
    state = const AsyncValue.loading();
    try {
      // Vérifier si l'utilisateur a déjà posté aujourd'hui
      final existing = await _db.getUserTodayPost(user.uid);
      if (existing != null) {
        state = const AsyncValue.data(null);
        return 'already_posted';
      }

      final refs = garments
          .map((g) => GarmentRef(name: g.name, brand: g.brand))
          .toList();

      final post = PostModel(
        userId: user.uid,
        username: user.username,
        userPhotoUrl: user.profilePhotoUrl,
        imageUrl: user.dailyPhotoUrl,
        outfitId: outfit.id,
        garmentRefs: refs,
        caption: caption,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );
      await _db.addPost(post);
      state = const AsyncValue.data(null);
      return 'ok';
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return 'error';
    }
  }

  Future<void> toggleLike(String postId, String uid) async {
    await _db.toggleLike(postId, uid);
  }

  /// Retourne true si supprimé, false sinon.
  Future<bool> deletePost(String postId) async {
    try {
      await _db.deletePost(postId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateCaption(String postId, String caption) async {
    await _db.updatePostCaption(postId, caption);
  }
}

final postNotifierProvider = StateNotifierProvider<PostNotifier, AsyncValue<void>>((ref) {
  return PostNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(storageServiceProvider),
  );
});
