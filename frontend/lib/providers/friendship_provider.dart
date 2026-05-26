import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_request_model.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final receivedRequestsProvider = StreamProvider<List<FriendRequestModel>>((ref) {
  final uid = ref.watch(authServiceProvider).uid;
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).receivedRequestsStream(uid);
});

final sentRequestsProvider = StreamProvider<List<FriendRequestModel>>((ref) {
  final uid = ref.watch(authServiceProvider).uid;
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).sentRequestsStream(uid);
});

final receivedRequestsCountProvider = Provider<int>((ref) {
  return ref.watch(receivedRequestsProvider).valueOrNull?.length ?? 0;
});

/// Profils amis (cache Riverpod + requêtes parallèles Firestore).
final friendUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.friends.isEmpty) return [];
  final users =
      await ref.read(firestoreServiceProvider).getUsersByIds(user.friends);
  final byId = {for (final u in users) u.uid: u};
  return [
    for (final id in user.friends)
      if (byId.containsKey(id)) byId[id]!,
  ];
});

final friendsPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  // Inclure mon propre UID pour que mes posts apparaissent dans le feed amis
  final feedUids = {...user.friends, if (user.uid.isNotEmpty) user.uid}.toList();
  if (feedUids.isEmpty) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).friendsPostsStream(feedUids);
});

final searchResultsProvider = StateProvider<List<UserModel>>((ref) => []);
final searchLoadingProvider = StateProvider<bool>((ref) => false);

class FriendshipNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _db;
  final String _uid;

  FriendshipNotifier(this._db, this._uid) : super(const AsyncValue.data(null));

  Future<bool> sendRequest({
    required UserModel from,
    required UserModel to,
  }) async {
    state = const AsyncValue.loading();
    try {
      final existing = await _db.findPendingRequest(from.uid, to.uid);
      if (existing != null) {
        state = const AsyncValue.data(null);
        return false;
      }
      final reverse = await _db.findPendingRequest(to.uid, from.uid);
      if (reverse != null) {
        await _db.acceptFriendRequest(reverse.id, to.uid, from.uid);
        state = const AsyncValue.data(null);
        return true;
      }
      final request = FriendRequestModel(
        fromUid: from.uid,
        toUid: to.uid,
        fromUsername: from.username,
        fromPhotoUrl: from.profilePhotoUrl,
        toUsername: to.username,
        toPhotoUrl: to.profilePhotoUrl,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _db.sendFriendRequest(request);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<bool> acceptRequest(FriendRequestModel request) async {
    state = const AsyncValue.loading();
    try {
      await _db.acceptFriendRequest(request.id, request.fromUid, request.toUid);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<void> rejectRequest(FriendRequestModel request) async {
    await _db.rejectFriendRequest(request.id);
  }

  Future<void> cancelRequest(FriendRequestModel request) async {
    await _db.cancelFriendRequest(request.id);
  }

  Future<void> removeFriend(String friendUid) async {
    await _db.removeFriend(_uid, friendUid);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    return _db.searchUsers(query);
  }

  Future<List<UserModel>> suggestUsers({
    required String currentUid,
    List<String> currentFriends = const [],
    int limit = 12,
  }) async {
    return _db.suggestUsers(
      currentUid: currentUid,
      currentFriends: currentFriends,
      limit: limit,
    );
  }

  Future<void> togglePrivacy(bool isPrivate) async {
    await _db.updateUser(_uid, {'is_private': isPrivate});
  }
}

final friendshipNotifierProvider =
    StateNotifierProvider<FriendshipNotifier, AsyncValue<void>>((ref) {
  return FriendshipNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(authServiceProvider).uid,
  );
});

enum RelationshipStatus { none, requestSent, requestReceived, friends }

final relationshipStatusProvider =
    FutureProvider.family<RelationshipStatus, String>((ref, targetUid) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return RelationshipStatus.none;
  if (user.friends.contains(targetUid)) return RelationshipStatus.friends;

  final db = ref.read(firestoreServiceProvider);
  final sent = await db.findPendingRequest(user.uid, targetUid);
  if (sent != null) return RelationshipStatus.requestSent;

  final received = await db.findPendingRequest(targetUid, user.uid);
  if (received != null) return RelationshipStatus.requestReceived;

  return RelationshipStatus.none;
});
