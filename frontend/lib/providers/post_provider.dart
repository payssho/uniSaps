import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/outfit_model.dart';
import '../models/garment_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/widget_sync_bridge.dart';
import 'auth_provider.dart';
import 'garment_provider.dart';
import '../data/mock_explore_feed_posts.dart';
import '../utils/feed_mix.dart';
import 'inspiration_feed_dev_provider.dart';

final postsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(firestoreServiceProvider).postsStream();
});

List<PostModel> _organicOnly(List<PostModel> all) =>
    all.where((p) => p.isOrganic && !p.isSponsored).toList();

/// Feed Explorer : organiques + sponsorisés actifs mélangés.
final exploreFeedProvider = Provider<AsyncValue<List<PostModel>>>((ref) {
  final all = ref.watch(postsProvider);
  final sponsoredAsync = ref.watch(_sponsoredActiveProvider);
  final mockAdsOn =
      kDebugMode && ref.watch(exploreDevMockPostsEnabledProvider);

  return all.when(
    data: (organicPosts) {
      final organic = _organicOnly(organicPosts);
      final sponsoredPosts = sponsoredAsync.valueOrNull ?? [];

      if (!mockAdsOn) {
        return sponsoredAsync.when(
          data: (_) => AsyncValue.data(
            mixExploreFeed(organic: organic, sponsoredActive: sponsoredPosts),
          ),
          loading: () => const AsyncValue.loading(),
          error: (e, st) => AsyncValue.error(e, st),
        );
      }

      // Mode dev : mocks en tête (organiques, sans pastille pub).
      // Mélange tous les 7 : uniquement les pubs Firestore (compte créateur, etc.).
      if (organic.isEmpty) {
        return AsyncValue.data(List<PostModel>.from(kMockExploreFeedPosts));
      }

      final mixed = mixExploreFeed(
        organic: organic,
        sponsoredActive: sponsoredPosts,
      );
      return AsyncValue.data([
        ...kMockExploreFeedPosts,
        ...mixed,
      ]);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

final _sponsoredActiveProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(firestoreServiceProvider).sponsoredActivePostsStream();
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
    if (p.isSponsored || p.postKind == 'sponsored') return false;
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
    bool authorIsPremium = false,
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
        authorIsPremium: authorIsPremium,
      );
      await _db.addPost(post);
      state = const AsyncValue.data(null);
      await WidgetSyncBridge.request();
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
    final imageUrl = user.dailyPhotoUrl.isNotEmpty
        ? user.dailyPhotoUrl
        : outfit.referencePhotoUrl;
    if (imageUrl.isEmpty) {
      state = AsyncValue.error('Aucune photo pour ce look.', StackTrace.current);
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
          .map((g) => GarmentRef(name: g.name, brand: g.brand, imageUrl: g.imageUrl))
          .toList();

      final post = PostModel(
        userId: user.uid,
        username: user.username,
        userPhotoUrl: user.profilePhotoUrl,
        imageUrl: imageUrl,
        outfitId: outfit.id,
        garmentRefs: refs,
        caption: caption,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        authorIsPremium: user.isPremium,
      );
      await _db.addPost(post);
      state = const AsyncValue.data(null);
      await WidgetSyncBridge.request();
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

/// Enrichit les refs du post avec les photos Firestore (posts anciens sans image_url).
final enrichedGarmentRefsProvider =
    FutureProvider.family<List<GarmentRef>, PostModel>((ref, post) async {
  if (post.garmentRefs.isEmpty) return post.garmentRefs;
  if (!post.garmentRefs.any((r) => r.imageUrl.isEmpty)) {
    return post.garmentRefs;
  }
  if (post.outfitId.isEmpty || post.userId.isEmpty) {
    return post.garmentRefs;
  }

  final db = ref.read(firestoreServiceProvider);
  final outfit = await db.getOutfit(post.userId, post.outfitId);
  if (outfit == null) return post.garmentRefs;

  final garments = <GarmentModel>[];
  for (final gid in outfit.garmentIds) {
    final g = await db.getGarment(post.userId, gid);
    if (g != null) garments.add(g);
  }
  if (garments.isEmpty) return post.garmentRefs;

  if (garments.length == post.garmentRefs.length) {
    return [
      for (var i = 0; i < garments.length; i++)
        GarmentRef(
          name: post.garmentRefs[i].name.isNotEmpty
              ? post.garmentRefs[i].name
              : garments[i].name,
          brand: post.garmentRefs[i].brand.isNotEmpty
              ? post.garmentRefs[i].brand
              : garments[i].brand,
          imageUrl: garments[i].imageUrl,
        ),
    ];
  }

  return post.garmentRefs.map((refItem) {
    GarmentModel? match;
    for (final g in garments) {
      if (g.name == refItem.name && g.brand == refItem.brand) {
        match = g;
        break;
      }
    }
    if (match != null && match.imageUrl.isNotEmpty) {
      return GarmentRef(
        name: refItem.name,
        brand: refItem.brand,
        imageUrl: match.imageUrl,
      );
    }
    return refItem;
  }).toList();
});
