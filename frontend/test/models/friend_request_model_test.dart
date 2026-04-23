import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/models/friend_request_model.dart';

void main() {
  group('FriendRequestModel', () {
    final fullMap = {
      'from_uid': 'uid-sender',
      'to_uid': 'uid-receiver',
      'from_username': 'alice',
      'from_photo_url': 'https://alice.photo',
      'to_username': 'bob',
      'to_photo_url': 'https://bob.photo',
      'status': 'pending',
      'created_at': '2026-01-01T00:00:00.000Z',
    };

    // ── fromMap ──────────────────────────────────────────────────────────────

    test('valeurs par défaut correctes', () {
      const r = FriendRequestModel();
      expect(r.id, '');
      expect(r.fromUid, '');
      expect(r.toUid, '');
      expect(r.status, FriendRequestStatus.pending);
    });

    test('fromMap lit tous les champs', () {
      final r = FriendRequestModel.fromMap(fullMap, docId: 'req-1');
      expect(r.id, 'req-1');
      expect(r.fromUid, 'uid-sender');
      expect(r.toUid, 'uid-receiver');
      expect(r.fromUsername, 'alice');
      expect(r.toUsername, 'bob');
      expect(r.status, FriendRequestStatus.pending);
      expect(r.createdAt, '2026-01-01T00:00:00.000Z');
    });

    test('fromMap gère les champs manquants', () {
      final r = FriendRequestModel.fromMap({});
      expect(r.fromUid, '');
      expect(r.status, FriendRequestStatus.pending);
    });

    test('fromMap utilise docId si id absent', () {
      final r = FriendRequestModel.fromMap({}, docId: 'injected');
      expect(r.id, 'injected');
    });

    // ── parseStatus ───────────────────────────────────────────────────────────

    test('status pending est parsé correctement', () {
      final r = FriendRequestModel.fromMap({...fullMap, 'status': 'pending'});
      expect(r.status, FriendRequestStatus.pending);
    });

    test('status accepted est parsé correctement', () {
      final r = FriendRequestModel.fromMap({...fullMap, 'status': 'accepted'});
      expect(r.status, FriendRequestStatus.accepted);
    });

    test('status rejected est parsé correctement', () {
      final r = FriendRequestModel.fromMap({...fullMap, 'status': 'rejected'});
      expect(r.status, FriendRequestStatus.rejected);
    });

    test('status inconnu → pending par défaut', () {
      final r = FriendRequestModel.fromMap({...fullMap, 'status': 'unknown'});
      expect(r.status, FriendRequestStatus.pending);
    });

    test('status null → pending par défaut', () {
      final r = FriendRequestModel.fromMap({...fullMap, 'status': null});
      expect(r.status, FriendRequestStatus.pending);
    });

    // ── toMap ────────────────────────────────────────────────────────────────

    test('toMap contient tous les champs attendus', () {
      final r = FriendRequestModel.fromMap(fullMap, docId: 'req-1');
      final map = r.toMap();
      expect(map['from_uid'], 'uid-sender');
      expect(map['to_uid'], 'uid-receiver');
      expect(map['from_username'], 'alice');
      expect(map['to_username'], 'bob');
      expect(map['status'], 'pending');
    });

    test('toMap sérialise accepted correctement', () {
      final r = FriendRequestModel.fromMap({...fullMap, 'status': 'accepted'});
      expect(r.toMap()['status'], 'accepted');
    });

    test('toMap sérialise rejected correctement', () {
      final r = FriendRequestModel.fromMap({...fullMap, 'status': 'rejected'});
      expect(r.toMap()['status'], 'rejected');
    });

    test('fromMap → toMap est idempotent pour pending', () {
      final r = FriendRequestModel.fromMap(fullMap, docId: 'r-1');
      final map = r.toMap();
      final r2 = FriendRequestModel.fromMap(map, docId: 'r-1');
      expect(r2.fromUid, r.fromUid);
      expect(r2.toUid, r.toUid);
      expect(r2.status, r.status);
    });

    test('fromMap → toMap est idempotent pour accepted', () {
      final map = {...fullMap, 'status': 'accepted'};
      final r = FriendRequestModel.fromMap(map);
      expect(r.toMap()['status'], 'accepted');
    });
  });
}
