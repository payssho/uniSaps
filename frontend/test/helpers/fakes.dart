// ignore_for_file: override_on_non_overriding_member

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/models/friend_request_model.dart';
import 'package:unisaps/models/garment_model.dart';
import 'package:unisaps/models/outfit_model.dart';
import 'package:unisaps/models/post_model.dart';
import 'package:unisaps/models/user_model.dart';
import 'package:unisaps/services/api_service.dart';
import 'package:unisaps/services/auth_service.dart';
import 'package:unisaps/services/firestore_service.dart';
import 'package:unisaps/services/storage_service.dart';

// ────────────────────────────────────────────────────────────────────────────
// FakeFirestoreService
// ────────────────────────────────────────────────────────────────────────────

class FakeFirestoreService extends Fake implements FirestoreService {
  // In-memory data
  final Map<String, Map<String, dynamic>> users = {};
  final Map<String, List<OutfitModel>> outfits = {};
  final Map<String, List<GarmentModel>> garments = {};
  final List<PostModel> posts = [];
  final List<FriendRequestModel> friendRequests = [];

  // Error injection
  Exception? nextError;

  void _checkError() {
    final e = nextError;
    nextError = null;
    if (e != null) throw e;
  }

  // ── Users ────────────────────────────────────────────────────────────────

  @override
  Future<void> createUser(UserModel user) async {
    _checkError();
    users[user.uid] = user.toMap();
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    _checkError();
    final data = users[uid];
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    _checkError();
    final existing = Map<String, dynamic>.from(users[uid] ?? {});
    for (final entry in data.entries) {
      final val = entry.value;
      if (val is FieldValue) {
        // Simulation basique de FieldValue.increment
        final current = existing[entry.key];
        if (current is int) {
          existing[entry.key] = current + 1;
        }
      } else {
        existing[entry.key] = val;
      }
    }
    users[uid] = existing;
  }

  @override
  Stream<UserModel?> userStream(String uid) {
    final data = users[uid];
    if (data == null) return Stream.value(null);
    return Stream.value(UserModel.fromMap(data));
  }

  // ── Outfits ──────────────────────────────────────────────────────────────

  int _outfitIdCounter = 0;

  @override
  Future<String> addOutfit(OutfitModel outfit) async {
    _checkError();
    final id = 'outfit-${++_outfitIdCounter}';
    outfits.putIfAbsent(outfit.userId, () => []).add(outfit.copyWith(id: id));
    return id;
  }

  @override
  Future<OutfitModel?> getOutfit(String uid, String outfitId) async {
    return outfits[uid]?.where((o) => o.id == outfitId).firstOrNull;
  }

  @override
  Future<void> updateOutfit(
      String uid, String outfitId, Map<String, dynamic> data) async {
    _checkError();
    final list = outfits[uid] ?? [];
    for (int i = 0; i < list.length; i++) {
      if (list[i].id == outfitId) {
        final map = list[i].toMap();
        for (final entry in data.entries) {
          final val = entry.value;
          if (val is FieldValue) {
            final current = map[entry.key];
            if (current is int) map[entry.key] = current + 1;
          } else {
            map[entry.key] = val;
          }
        }
        list[i] = OutfitModel.fromMap(map, docId: outfitId);
      }
    }
  }

  @override
  Future<void> deleteOutfit(String uid, String outfitId) async {
    _checkError();
    outfits[uid]?.removeWhere((o) => o.id == outfitId);
  }

  @override
  Stream<List<OutfitModel>> outfitsStream(String uid) =>
      Stream.value(outfits[uid] ?? []);

  // ── Garments ─────────────────────────────────────────────────────────────

  int _garmentIdCounter = 0;

  @override
  Future<String> addGarment(GarmentModel garment) async {
    _checkError();
    final id = 'garment-${++_garmentIdCounter}';
    garments
        .putIfAbsent(garment.userId, () => [])
        .add(garment.copyWith(id: id));
    return id;
  }

  @override
  Future<GarmentModel?> getGarment(String uid, String garmentId) async {
    return garments[uid]?.where((g) => g.id == garmentId).firstOrNull;
  }

  @override
  Future<void> updateGarment(
      String uid, String garmentId, Map<String, dynamic> data) async {
    _checkError();
    final list = garments[uid] ?? [];
    for (int i = 0; i < list.length; i++) {
      if (list[i].id == garmentId) {
        final map = list[i].toMap();
        map.addAll(data);
        list[i] = GarmentModel.fromMap(map, docId: garmentId);
      }
    }
  }

  @override
  Future<void> deleteGarment(String uid, String garmentId) async {
    _checkError();
    garments[uid]?.removeWhere((g) => g.id == garmentId);
  }

  @override
  Stream<List<GarmentModel>> garmentsStream(String uid,
          {String category = ''}) =>
      Stream.value(garments[uid] ?? []);

  // ── Posts ─────────────────────────────────────────────────────────────────

  int _postIdCounter = 0;

  @override
  Future<String> addPost(PostModel post) async {
    _checkError();
    final id = 'post-${++_postIdCounter}';
    posts.add(PostModel.fromMap({...post.toMap(), 'liked_by': []}, docId: id));
    return id;
  }

  @override
  Future<bool> toggleLike(String postId, String uid) async {
    _checkError();
    final i = posts.indexWhere((p) => p.id == postId);
    if (i == -1) return false;
    final p = posts[i];
    final likedBy = List<String>.from(p.likedBy);
    if (likedBy.contains(uid)) {
      likedBy.remove(uid);
      posts[i] = PostModel.fromMap(
          {...p.toMap(), 'liked_by': likedBy, 'likes': p.likes - 1},
          docId: postId);
      return false;
    } else {
      likedBy.add(uid);
      posts[i] = PostModel.fromMap(
          {...p.toMap(), 'liked_by': likedBy, 'likes': p.likes + 1},
          docId: postId);
      return true;
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    _checkError();
    posts.removeWhere((p) => p.id == postId);
  }

  @override
  Stream<List<PostModel>> postsStream({int limit = 50}) =>
      Stream.value(posts.take(limit).toList());

  // ── Friend Requests ───────────────────────────────────────────────────────

  int _requestIdCounter = 0;

  @override
  Future<void> sendFriendRequest(FriendRequestModel request) async {
    _checkError();
    final id = 'req-${++_requestIdCounter}';
    friendRequests
        .add(FriendRequestModel.fromMap(request.toMap(), docId: id));
  }

  @override
  Future<FriendRequestModel?> findPendingRequest(
      String fromUid, String toUid) async {
    return friendRequests
        .where((r) =>
            r.fromUid == fromUid &&
            r.toUid == toUid &&
            r.status == FriendRequestStatus.pending)
        .firstOrNull;
  }

  @override
  Future<void> acceptFriendRequest(
      String requestId, String fromUid, String toUid) async {
    _checkError();
    final i = friendRequests.indexWhere((r) => r.id == requestId);
    if (i != -1) {
      final r = friendRequests[i];
      friendRequests[i] = FriendRequestModel.fromMap(
          {...r.toMap(), 'status': 'accepted'}, docId: requestId);
    }
    // Add to friends list
    final fromMap = users[fromUid] ?? {};
    final toMap = users[toUid] ?? {};
    final fromFriends = List<String>.from(fromMap['friends'] ?? [])..add(toUid);
    final toFriends = List<String>.from(toMap['friends'] ?? [])..add(fromUid);
    users[fromUid] = {...fromMap, 'friends': fromFriends};
    users[toUid] = {...toMap, 'friends': toFriends};
  }

  @override
  Future<void> rejectFriendRequest(String requestId) async {
    final i = friendRequests.indexWhere((r) => r.id == requestId);
    if (i != -1) {
      final r = friendRequests[i];
      friendRequests[i] = FriendRequestModel.fromMap(
          {...r.toMap(), 'status': 'rejected'}, docId: requestId);
    }
  }

  @override
  Future<void> cancelFriendRequest(String requestId) async {
    friendRequests.removeWhere((r) => r.id == requestId);
  }

  @override
  Future<void> removeFriend(String myUid, String friendUid) async {
    final myMap = users[myUid] ?? {};
    final friendMap = users[friendUid] ?? {};
    final myFriends = List<String>.from(myMap['friends'] ?? [])
      ..remove(friendUid);
    final friendFriends = List<String>.from(friendMap['friends'] ?? [])
      ..remove(myUid);
    users[myUid] = {...myMap, 'friends': myFriends};
    users[friendUid] = {...friendMap, 'friends': friendFriends};
  }

  @override
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];
    final lower = query.toLowerCase();
    return users.values
        .map((m) => UserModel.fromMap(m))
        .where((u) => u.username.toLowerCase().contains(lower))
        .take(limit)
        .toList();
  }

  @override
  Stream<List<FriendRequestModel>> receivedRequestsStream(String uid) =>
      Stream.value(friendRequests
          .where((r) =>
              r.toUid == uid && r.status == FriendRequestStatus.pending)
          .toList());

  @override
  Stream<List<FriendRequestModel>> sentRequestsStream(String uid) =>
      Stream.value(friendRequests
          .where((r) =>
              r.fromUid == uid && r.status == FriendRequestStatus.pending)
          .toList());

}

// ────────────────────────────────────────────────────────────────────────────
// FakeAuthService
// ────────────────────────────────────────────────────────────────────────────

class FakeAuthService extends Fake implements AuthService {
  bool _shouldFail = false;
  Exception? _error;
  String _uid = 'test-uid';

  void mockSuccess({String uid = 'test-uid'}) {
    _shouldFail = false;
    _uid = uid;
    _error = null;
  }

  void mockFailure(Exception error) {
    _shouldFail = true;
    _error = error;
  }

  @override
  String get uid => _uid;

  @override
  User? get currentUser => null;

  @override
  bool get isSignedIn => false;

  @override
  Future<void> signIn(String email, String password) async {
    if (_shouldFail) throw _error!;
  }

  @override
  Future<void> signUp(String email, String password) async {
    if (_shouldFail) throw _error!;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getIdToken() async => 'fake-token';
}

// ────────────────────────────────────────────────────────────────────────────
// FakeStorageService
// ────────────────────────────────────────────────────────────────────────────

class FakeStorageService extends Fake implements StorageService {
  final List<String> deletedUrls = [];
  String uploadResult = 'https://fake.url/image.jpg';
  Exception? nextError;

  @override
  Future<String> uploadImageBytes(
      Uint8List bytes, String folder, String userId, String originalName) async {
    if (nextError != null) {
      final e = nextError!;
      nextError = null;
      throw e;
    }
    return uploadResult;
  }

  @override
  Future<String> uploadGarmentImageBytes(
      Uint8List bytes, String userId, String originalName) async {
    return uploadResult;
  }

  @override
  Future<String> uploadOutfitPhotoBytes(
      Uint8List bytes, String userId, String originalName) async {
    return uploadResult;
  }

  @override
  Future<String> uploadProfilePhotoBytes(
      Uint8List bytes, String userId, String originalName) async {
    return uploadResult;
  }

  @override
  Future<String> uploadPostImageBytes(
      Uint8List bytes, String userId, String originalName) async {
    if (nextError != null) {
      final e = nextError!;
      nextError = null;
      throw e;
    }
    return uploadResult;
  }

  @override
  Future<void> deleteImage(String url) async {
    deletedUrls.add(url);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// FakeApiService
// ────────────────────────────────────────────────────────────────────────────

class FakeApiService extends Fake implements ApiService {
  String uploadResult = 'https://fake.url/garment.jpg';
  Exception? nextError;

  @override
  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String filename,
    required String folder,
    bool removeBackground = false,
  }) async {
    if (nextError != null) {
      final e = nextError!;
      nextError = null;
      throw e;
    }
    return uploadResult;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Helper factories
// ────────────────────────────────────────────────────────────────────────────

UserModel fakeUser({
  String uid = 'uid-1',
  String username = 'testuser',
  String dailyOutfitId = '',
  int currentStreak = 0,
  List<String> friends = const [],
}) =>
    UserModel(
      uid: uid,
      email: 'test@example.com',
      username: username,
      displayName: 'Test User',
      isNewUser: false,
      dailyOutfitId: dailyOutfitId,
      currentStreak: currentStreak,
      friends: friends,
    );

OutfitModel fakeOutfit({
  String id = 'outfit-1',
  String userId = 'uid-1',
  String name = 'Test Outfit',
  int timesWorn = 0,
}) =>
    OutfitModel(
      id: id,
      userId: userId,
      name: name,
      garments: const {'top': 'g-1', 'bottom': 'g-2'},
      createdAt: '2026-01-01T00:00:00.000Z',
      timesWorn: timesWorn,
    );

GarmentModel fakeGarment({
  String id = 'g-1',
  String userId = 'uid-1',
  String name = 'T-Shirt',
  String imageUrl = 'https://fake.url/img.jpg',
}) =>
    GarmentModel(
      id: id,
      userId: userId,
      name: name,
      brand: 'Nike',
      colors: const ['Blanc'],
      category: 'top',
      imageUrl: imageUrl,
      createdAt: '2026-01-01T00:00:00.000Z',
    );

PostModel fakePost({
  String id = 'post-1',
  String userId = 'uid-1',
  List<String> likedBy = const [],
}) =>
    PostModel(
      id: id,
      userId: userId,
      username: 'testuser',
      imageUrl: 'https://fake.url/post.jpg',
      likedBy: likedBy,
      likes: likedBy.length,
      createdAt: '2026-01-01T00:00:00.000Z',
    );
