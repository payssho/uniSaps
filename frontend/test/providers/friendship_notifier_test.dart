import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/models/friend_request_model.dart';
import 'package:unisaps/providers/auth_provider.dart';
import 'package:unisaps/providers/friendship_provider.dart';
import '../helpers/fakes.dart';

void main() {
  late FakeFirestoreService fakeDb;
  late FakeAuthService fakeAuth;
  late ProviderContainer container;

  const myUid = 'uid-me';
  const friendUid = 'uid-friend';

  final alice = fakeUser(uid: myUid, username: 'alice');
  final bob = fakeUser(uid: friendUid, username: 'bob');

  setUp(() {
    fakeDb = FakeFirestoreService();
    fakeAuth = FakeAuthService()..mockSuccess(uid: myUid);
    fakeDb.users[myUid] = alice.toMap();
    fakeDb.users[friendUid] = bob.toMap();

    container = ProviderContainer(overrides: [
      firestoreServiceProvider.overrideWithValue(fakeDb),
      authServiceProvider.overrideWithValue(fakeAuth),
    ]);
  });

  tearDown(() => container.dispose());

  FriendshipNotifier n() => container.read(friendshipNotifierProvider.notifier);

  // ── sendRequest ────────────────────────────────────────────────────────────

  group('sendRequest', () {
    test('succès (pas de demande existante) → retourne true', () async {
      final ok = await n().sendRequest(from: alice, to: bob);
      expect(ok, true);
    });

    test('succès → demande enregistrée dans fakeDb', () async {
      await n().sendRequest(from: alice, to: bob);
      expect(fakeDb.friendRequests, isNotEmpty);
      expect(fakeDb.friendRequests.first.fromUid, myUid);
      expect(fakeDb.friendRequests.first.toUid, friendUid);
    });

    test('demande déjà envoyée → retourne false', () async {
      await n().sendRequest(from: alice, to: bob);
      final ok = await n().sendRequest(from: alice, to: bob);
      expect(ok, false);
    });

    test('demande inverse existante → accepte directement', () async {
      await n().sendRequest(from: bob, to: alice);
      final ok = await n().sendRequest(from: alice, to: bob);
      expect(ok, true);
      final aliceFriends = List<String>.from(fakeDb.users[myUid]!['friends'] ?? []);
      expect(aliceFriends, contains(friendUid));
    });

    test('état initial est AsyncData(null)', () {
      expect(container.read(friendshipNotifierProvider).hasValue, true);
    });
  });

  // ── acceptRequest ─────────────────────────────────────────────────────────

  group('acceptRequest', () {
    late FriendRequestModel request;

    setUp(() async {
      await n().sendRequest(from: bob, to: alice);
      request = fakeDb.friendRequests.first;
    });

    test('accepter → retourne true', () async {
      final ok = await n().acceptRequest(request);
      expect(ok, true);
    });

    test('accepter → statut devient accepted', () async {
      await n().acceptRequest(request);
      expect(fakeDb.friendRequests.first.status, FriendRequestStatus.accepted);
    });

    test('accepter → les deux users sont amis', () async {
      await n().acceptRequest(request);
      final bobFriends = List<String>.from(fakeDb.users[friendUid]!['friends'] ?? []);
      final aliceFriends = List<String>.from(fakeDb.users[myUid]!['friends'] ?? []);
      expect(bobFriends, contains(myUid));
      expect(aliceFriends, contains(friendUid));
    });

    test('erreur Firestore → retourne false', () async {
      fakeDb.nextError = Exception('Firestore error');
      final ok = await n().acceptRequest(request);
      expect(ok, false);
    });
  });

  // ── rejectRequest ──────────────────────────────────────────────────────────

  group('rejectRequest', () {
    late FriendRequestModel request;

    setUp(() async {
      await n().sendRequest(from: bob, to: alice);
      request = fakeDb.friendRequests.first;
    });

    test('rejeter → statut devient rejected', () async {
      await n().rejectRequest(request);
      expect(fakeDb.friendRequests.first.status, FriendRequestStatus.rejected);
    });

    test('rejeter → les users ne sont pas amis', () async {
      await n().rejectRequest(request);
      final aliceFriends = List<String>.from(fakeDb.users[myUid]!['friends'] ?? []);
      expect(aliceFriends, isNot(contains(friendUid)));
    });
  });

  // ── cancelRequest ──────────────────────────────────────────────────────────

  group('cancelRequest', () {
    late FriendRequestModel request;

    setUp(() async {
      await n().sendRequest(from: alice, to: bob);
      request = fakeDb.friendRequests.first;
    });

    test('annuler → demande supprimée de la DB', () async {
      await n().cancelRequest(request);
      expect(fakeDb.friendRequests, isEmpty);
    });
  });

  // ── removeFriend ──────────────────────────────────────────────────────────

  group('removeFriend', () {
    setUp(() {
      fakeDb.users[myUid] = fakeUser(uid: myUid, friends: [friendUid]).toMap();
      fakeDb.users[friendUid] = fakeUser(uid: friendUid, friends: [myUid]).toMap();
    });

    test('supprimer ami → retiré de la liste de l\'user', () async {
      await n().removeFriend(friendUid);
      final aliceFriends = List<String>.from(fakeDb.users[myUid]!['friends'] ?? []);
      expect(aliceFriends, isNot(contains(friendUid)));
    });

    test('supprimer ami → retiré de la liste de l\'ami aussi', () async {
      await n().removeFriend(friendUid);
      final bobFriends = List<String>.from(fakeDb.users[friendUid]!['friends'] ?? []);
      expect(bobFriends, isNot(contains(myUid)));
    });
  });

  // ── searchUsers ────────────────────────────────────────────────────────────

  group('searchUsers', () {
    setUp(() {
      fakeDb.users['uid-charlie'] = fakeUser(uid: 'uid-charlie', username: 'charlie').toMap();
      fakeDb.users['uid-charles'] = fakeUser(uid: 'uid-charles', username: 'charles').toMap();
    });

    test('requête vide → liste vide', () async {
      final results = await n().searchUsers('');
      expect(results, isEmpty);
    });

    test('requête partielle → trouve les utilisateurs correspondants', () async {
      final results = await n().searchUsers('char');
      expect(results.map((u) => u.username).toList(),
          containsAll(['charlie', 'charles']));
    });

    test('requête sans correspondance → liste vide', () async {
      final results = await n().searchUsers('xxxxxx');
      expect(results, isEmpty);
    });

    test('requête exacte → trouve l\'utilisateur', () async {
      final results = await n().searchUsers('alice');
      expect(results.map((u) => u.username).toList(), contains('alice'));
    });
  });

  // ── togglePrivacy ─────────────────────────────────────────────────────────

  group('togglePrivacy', () {
    test('passer en privé → is_private mis à true', () async {
      await n().togglePrivacy(true);
      expect(fakeDb.users[myUid]!['is_private'], true);
    });

    test('passer en public → is_private mis à false', () async {
      fakeDb.users[myUid]!['is_private'] = true;
      await n().togglePrivacy(false);
      expect(fakeDb.users[myUid]!['is_private'], false);
    });
  });
}
