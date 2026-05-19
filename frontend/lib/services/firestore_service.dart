import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../models/garment_model.dart';
import '../models/outfit_model.dart';
import '../models/post_model.dart';
import '../models/friend_request_model.dart';
import '../models/collection_model.dart';
import '../data/mock_explore_feed_posts.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ──────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromMap(snap.data()!);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromMap(snap.data()!);
    });
  }

  // ── Garments ───────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _garmentCol(String uid) =>
      _db.collection('users').doc(uid).collection('garments');

  Future<String> addGarment(GarmentModel garment) async {
    final ref = await _garmentCol(garment.userId).add(garment.toMap());
    return ref.id;
  }

  Future<List<GarmentModel>> getGarments(String uid, {String category = ''}) async {
    Query<Map<String, dynamic>> q = _garmentCol(uid);
    if (category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => GarmentModel.fromMap(d.data(), docId: d.id))
        .toList();
  }

  Stream<List<GarmentModel>> garmentsStream(String uid, {String category = ''}) {
    Query<Map<String, dynamic>> q = _garmentCol(uid);
    if (category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    return q.snapshots().map((snap) =>
        snap.docs.map((d) => GarmentModel.fromMap(d.data(), docId: d.id)).toList());
  }

  Future<GarmentModel?> getGarment(String uid, String garmentId) async {
    final snap = await _garmentCol(uid).doc(garmentId).get();
    if (!snap.exists) return null;
    return GarmentModel.fromMap(snap.data()!, docId: snap.id);
  }

  Stream<GarmentModel?> garmentStream(String uid, String garmentId) {
    return _garmentCol(uid)
        .doc(garmentId)
        .snapshots()
        .map((snap) => snap.exists ? GarmentModel.fromMap(snap.data()!, docId: snap.id) : null);
  }

  Future<void> updateGarment(String uid, String garmentId, Map<String, dynamic> data) async {
    await _garmentCol(uid).doc(garmentId).update(data);
  }

  Future<void> deleteGarment(String uid, String garmentId) async {
    await _garmentCol(uid).doc(garmentId).delete();
  }

  // ── Outfits ────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _outfitCol(String uid) =>
      _db.collection('users').doc(uid).collection('outfits');

  Future<String> addOutfit(OutfitModel outfit) async {
    final ref = await _outfitCol(outfit.userId).add(outfit.toMap());
    return ref.id;
  }

  Future<List<OutfitModel>> getOutfits(String uid) async {
    final snap = await _outfitCol(uid)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs
        .map((d) => OutfitModel.fromMap(d.data(), docId: d.id))
        .toList();
  }

  Stream<List<OutfitModel>> outfitsStream(String uid) {
    return _outfitCol(uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OutfitModel.fromMap(d.data(), docId: d.id)).toList());
  }

  Future<OutfitModel?> getOutfit(String uid, String outfitId) async {
    final snap = await _outfitCol(uid).doc(outfitId).get();
    if (!snap.exists) return null;
    return OutfitModel.fromMap(snap.data()!, docId: snap.id);
  }

  Future<void> updateOutfit(String uid, String outfitId, Map<String, dynamic> data) async {
    await _outfitCol(uid).doc(outfitId).update(data);
  }

  Future<void> deleteOutfit(String uid, String outfitId) async {
    await _outfitCol(uid).doc(outfitId).delete();
  }

  // ── Collections (compte créateur) ───────────────────────────────────

  CollectionReference<Map<String, dynamic>> _collectionCol(String uid) =>
      _db.collection('users').doc(uid).collection('collections');

  Future<String> addCollection(CollectionModel collection) async {
    final ref = await _collectionCol(collection.userId).add(collection.toMap());
    return ref.id;
  }

  Future<List<CollectionModel>> getCollections(String uid) async {
    final snap = await _collectionCol(uid)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs
        .map((d) => CollectionModel.fromMap(d.data(), docId: d.id))
        .toList();
  }

  Future<List<GarmentModel>> getGarmentsByCollectionId(String uid, String collectionId) async {
    if (collectionId.isEmpty) return [];
    final snap =
        await _garmentCol(uid).where('collection_id', isEqualTo: collectionId).get();
    return snap.docs.map((d) => GarmentModel.fromMap(d.data(), docId: d.id)).toList();
  }

  Future<void> deleteCollectionDocument(String uid, String collectionId) async {
    await _collectionCol(uid).doc(collectionId).delete();
  }

  Stream<List<CollectionModel>> collectionsStream(String uid) {
    return _collectionCol(uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CollectionModel.fromMap(d.data(), docId: d.id))
            .toList());
  }

  // ── Posts ──────────────────────────────────────────────────────────

  final _postCol = FirebaseFirestore.instance.collection('posts');

  Future<String> addPost(PostModel post) async {
    final ref = await _postCol.add(post.toMap());
    return ref.id;
  }

  Future<List<PostModel>> getPosts({int limit = 50}) async {
    final snap = await _postCol
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => PostModel.fromMap(d.data(), docId: d.id))
        .toList();
  }

  Stream<List<PostModel>> postsStream({int limit = 50}) {
    return _postCol
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PostModel.fromMap(d.data(), docId: d.id)).toList());
  }

  /// Posts sponsorisés actifs pour le fil Explorer (indépendamment des X derniers posts).
  ///
  /// Ne pas dériver de [postsStream] avec une petite limite globale : les publications
  /// organiques récentes poussaient les pubs hors fenêtre et elles n’apparaissaient jamais.
  Stream<List<PostModel>> sponsoredActivePostsStream({int limit = 50}) {
    return _postCol
        .where('is_sponsored', isEqualTo: true)
        .limit(200)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => PostModel.fromMap(d.data(), docId: d.id))
              .where((p) =>
                  p.isActive &&
                  !isDevMockExplorePostId(p.id) &&
                  (p.isSponsored || p.postKind == 'sponsored'))
              .toList();
          list.sort((a, b) {
            final da = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
            final db = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
            return db.compareTo(da);
          });
          return list.take(limit).toList();
        });
  }

  Stream<List<PostModel>> creatorPostsStream(String uid, {int limit = 80}) {
    return _postCol
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PostModel.fromMap(d.data(), docId: d.id))
            .where((p) => p.postKind == 'sponsored' || p.isSponsored)
            .toList());
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    await _postCol.doc(postId).update(data);
  }

  Future<bool> toggleLike(String postId, String uid) async {
    // Posts factices Explorer (dev) : pas de document Firestore.
    if (isDevMockExplorePostId(postId)) {
      return false;
    }
    final ref = _postCol.doc(postId);
    final snap = await ref.get();
    final likedBy = List<String>.from(snap.data()?['liked_by'] ?? []);
    if (likedBy.contains(uid)) {
      await ref.update({
        'liked_by': FieldValue.arrayRemove([uid]),
        'likes': FieldValue.increment(-1),
      });
      return false;
    } else {
      await ref.update({
        'liked_by': FieldValue.arrayUnion([uid]),
        'likes': FieldValue.increment(1),
      });
      return true;
    }
  }

  Future<void> deletePost(String postId) async {
    if (postId.isEmpty) throw Exception('ID du post invalide.');
    if (isDevMockExplorePostId(postId)) return;
    await _postCol.doc(postId).delete();
  }

  Future<void> updatePostCaption(String postId, String caption) async {
    if (isDevMockExplorePostId(postId)) return;
    await _postCol.doc(postId).update({'caption': caption});
  }

  /// Retourne le post du jour de l'utilisateur s'il existe, null sinon.
  /// Utilise un seul where pour éviter l'index composite Firestore, filtre par date côté client.
  Future<PostModel?> getUserTodayPost(String uid) async {
    final snap = await _postCol
        .where('user_id', isEqualTo: uid)
        .limit(20)
        .get();
    if (snap.docs.isEmpty) return null;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    for (final doc in snap.docs) {
      final post = PostModel.fromMap(doc.data(), docId: doc.id);
      final dt = DateTime.tryParse(post.createdAt)?.toLocal();
      if (dt != null && dt.isAfter(todayStart) && dt.isBefore(todayEnd)) {
        return post;
      }
    }
    return null;
  }

  // ── Friends ──────────────────────────────────────────────────────

  final _friendRequestCol = FirebaseFirestore.instance.collection('friend_requests');

  Future<void> sendFriendRequest(FriendRequestModel request) async {
    await _friendRequestCol.add(request.toMap());
  }

  // Requête simple sur 1 seul champ (pas d'index composite requis),
  // filtrages status + tri côté client.
  Stream<List<FriendRequestModel>> receivedRequestsStream(String uid) {
    return _friendRequestCol
        .where('to_uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .map((d) => FriendRequestModel.fromMap(d.data(), docId: d.id))
          .where((r) => r.status == FriendRequestStatus.pending)
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  Stream<List<FriendRequestModel>> sentRequestsStream(String uid) {
    return _friendRequestCol
        .where('from_uid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FriendRequestModel.fromMap(d.data(), docId: d.id))
            .where((r) => r.status == FriendRequestStatus.pending)
            .toList());
  }

  Future<FriendRequestModel?> findPendingRequest(String fromUid, String toUid) async {
    // Requête sur 1 seul champ pour éviter l'index composite Firestore.
    final snap = await _friendRequestCol
        .where('from_uid', isEqualTo: fromUid)
        .limit(50)
        .get();
    for (final doc in snap.docs) {
      final r = FriendRequestModel.fromMap(doc.data(), docId: doc.id);
      if (r.toUid == toUid && r.status == FriendRequestStatus.pending) {
        return r;
      }
    }
    return null;
  }

  Future<void> acceptFriendRequest(String requestId, String fromUid, String toUid) async {
    final batch = _db.batch();
    batch.update(_friendRequestCol.doc(requestId), {'status': 'accepted'});
    batch.update(_db.collection('users').doc(fromUid), {
      'friends': FieldValue.arrayUnion([toUid]),
    });
    batch.update(_db.collection('users').doc(toUid), {
      'friends': FieldValue.arrayUnion([fromUid]),
    });
    await batch.commit();
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _friendRequestCol.doc(requestId).update({'status': 'rejected'});
  }

  Future<void> removeFriend(String myUid, String friendUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(myUid), {
      'friends': FieldValue.arrayRemove([friendUid]),
    });
    batch.update(_db.collection('users').doc(friendUid), {
      'friends': FieldValue.arrayRemove([myUid]),
    });
    await batch.commit();
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await _friendRequestCol.doc(requestId).delete();
  }

  /// Supprime le document utilisateur principal (les sous-collections restent,
  /// une Cloud Function serait nécessaire pour un nettoyage complet).
  Future<void> deleteUserData(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ── Search ──────────────────────────────────────────────────────

  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];
    final lower = query.trim().toLowerCase();
    final snap = await _db
        .collection('users')
        .limit(200)
        .get();
    final results = snap.docs
        .map((d) => UserModel.fromMap(d.data()))
        .where((u) {
          final username = u.username.toLowerCase();
          final displayName = u.displayName.toLowerCase();
          return username.contains(lower) || displayName.contains(lower);
        })
        .toList();
    results.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    return results.take(limit).toList();
  }

  Future<List<UserModel>> suggestUsers({
    required String currentUid,
    List<String> currentFriends = const [],
    int limit = 12,
  }) async {
    final snap = await _db.collection('users').limit(200).get();
    final candidates = snap.docs
        .map((d) => UserModel.fromMap(d.data()))
        .where((u) =>
            u.uid.isNotEmpty &&
            u.uid != currentUid &&
            !currentFriends.contains(u.uid))
        .toList();

    if (candidates.isEmpty) return [];

    int mutualCount(UserModel u) =>
        u.friends.where((id) => currentFriends.contains(id)).length;

    final friendsOfFriends = candidates.where((u) => mutualCount(u) > 0).toList()
      ..sort((a, b) => mutualCount(b).compareTo(mutualCount(a)));

    final others = candidates.where((u) => mutualCount(u) == 0).toList()
      ..shuffle(Random());

    final merged = <UserModel>[
      ...friendsOfFriends,
      ...others,
    ];
    return merged.take(limit).toList();
  }

  // ── User Profile (other) ────────────────────────────────────────

  Future<List<PostModel>> getUserPosts(String uid, {int limit = 50}) async {
    final snap = await _postCol
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => PostModel.fromMap(d.data(), docId: d.id))
        .toList();
  }

  // ── Filtered Posts ──────────────────────────────────────────────

  Stream<List<PostModel>> friendsPostsStream(List<String> friendUids, {int limit = 50}) {
    if (friendUids.isEmpty) return Stream.value([]);
    final batches = <List<String>>[];
    for (var i = 0; i < friendUids.length; i += 30) {
      batches.add(friendUids.sublist(i, i + 30 > friendUids.length ? friendUids.length : i + 30));
    }
    if (batches.length == 1) {
      return _postCol
          .where('user_id', whereIn: batches[0])
          .orderBy('created_at', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs.map((d) => PostModel.fromMap(d.data(), docId: d.id)).toList());
    }
    final streams = batches.map((batch) => _postCol
        .where('user_id', whereIn: batch)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostModel.fromMap(d.data(), docId: d.id)).toList()));
    return streams.reduce((a, b) => a.asyncExpand((aList) => b.map((bList) {
          final merged = [...aList, ...bList];
          merged.sort((x, y) => y.createdAt.compareTo(x.createdAt));
          return merged.take(limit).toList();
        })));
  }

  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    final results = <UserModel>[];
    final batches = <List<String>>[];
    for (var i = 0; i < uids.length; i += 30) {
      batches.add(uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30));
    }
    for (final batch in batches) {
      final snap = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      results.addAll(snap.docs.map((d) => UserModel.fromMap(d.data())));
    }
    return results;
  }

  // ── Statistics ─────────────────────────────────────────────────────

  Future<int> garmentCount(String uid) async {
    final snap = await _garmentCol(uid).count().get();
    return snap.count ?? 0;
  }

  Future<int> outfitCount(String uid) async {
    final snap = await _outfitCol(uid).count().get();
    return snap.count ?? 0;
  }

  Future<int> wornOutfitCount(String uid) async {
    final snap = await _outfitCol(uid).where('times_worn', isGreaterThan: 0).count().get();
    return snap.count ?? 0;
  }

  Future<List<GarmentModel>> mostWornGarments(String uid, {int limit = 5}) async {
    final snap = await _garmentCol(uid)
        .orderBy('times_worn', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => GarmentModel.fromMap(d.data(), docId: d.id))
        .toList();
  }
}
