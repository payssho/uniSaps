import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/garment_model.dart';
import '../models/outfit_model.dart';
import '../models/post_model.dart';

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

  Future<bool> toggleLike(String postId, String uid) async {
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
    await _postCol.doc(postId).delete();
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
