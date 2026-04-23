import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/models/user_model.dart';

void main() {
  // ── TutorialState ──────────────────────────────────────────────────────────

  group('TutorialState', () {
    test('valeurs par défaut sont false', () {
      const state = TutorialState();
      expect(state.dressing, false);
      expect(state.creations, false);
      expect(state.outfits, false);
      expect(state.profile, false);
      expect(state.inspiration, false);
    });

    test('fromMap lit correctement les champs', () {
      final state = TutorialState.fromMap({
        'dressing': true,
        'creations': true,
        'outfits': false,
        'profile': true,
        'inspiration': false,
      });
      expect(state.dressing, true);
      expect(state.creations, true);
      expect(state.outfits, false);
      expect(state.profile, true);
      expect(state.inspiration, false);
    });

    test('fromMap gère les champs manquants (null → false)', () {
      final state = TutorialState.fromMap({});
      expect(state.dressing, false);
      expect(state.outfits, false);
    });

    test('toMap produit les bons champs', () {
      const state = TutorialState(dressing: true, outfits: true);
      final map = state.toMap();
      expect(map['dressing'], true);
      expect(map['outfits'], true);
      expect(map['creations'], false);
      expect(map['profile'], false);
      expect(map['inspiration'], false);
    });

    test('copyWith ne modifie que les champs spécifiés', () {
      const state = TutorialState(dressing: true, outfits: true);
      final copy = state.copyWith(outfits: false, inspiration: true);
      expect(copy.dressing, true);
      expect(copy.outfits, false);
      expect(copy.inspiration, true);
      expect(copy.creations, false);
    });

    test('fromMap → toMap est idempotent', () {
      final map = {
        'dressing': true,
        'creations': false,
        'outfits': true,
        'profile': false,
        'inspiration': true,
      };
      final result = TutorialState.fromMap(map).toMap();
      expect(result, map);
    });
  });

  // ── UserModel ──────────────────────────────────────────────────────────────

  group('UserModel', () {
    final fullMap = {
      'uid': 'uid-123',
      'email': 'test@example.com',
      'username': 'testuser',
      'display_name': 'Test User',
      'profile_photo_url': 'https://pic.url',
      'created_at': '2026-01-01T00:00:00.000Z',
      'tutorial_seen': {
        'dressing': true,
        'creations': true,
        'outfits': true,
        'profile': false,
        'inspiration': false,
      },
      'current_streak': 5,
      'best_streak': 10,
      'daily_outfit_id': 'outfit-abc',
      'daily_outfit_date': '2026-01-01',
      'daily_photo_url': 'https://photo.url',
      'is_new_user': false,
      'is_private': true,
      'friends': ['uid-2', 'uid-3'],
    };

    test('valeurs par défaut correctes', () {
      const user = UserModel();
      expect(user.uid, '');
      expect(user.email, '');
      expect(user.currentStreak, 0);
      expect(user.bestStreak, 0);
      expect(user.dailyOutfitId, '');
      expect(user.isNewUser, true);
      expect(user.isPrivate, false);
      expect(user.friends, isEmpty);
    });

    test('fromMap lit tous les champs', () {
      final user = UserModel.fromMap(fullMap);
      expect(user.uid, 'uid-123');
      expect(user.email, 'test@example.com');
      expect(user.username, 'testuser');
      expect(user.displayName, 'Test User');
      expect(user.currentStreak, 5);
      expect(user.bestStreak, 10);
      expect(user.dailyOutfitId, 'outfit-abc');
      expect(user.dailyOutfitDate, '2026-01-01');
      expect(user.isNewUser, false);
      expect(user.isPrivate, true);
      expect(user.friends, ['uid-2', 'uid-3']);
      expect(user.tutorialSeen.dressing, true);
    });

    test('fromMap gère les champs manquants', () {
      final user = UserModel.fromMap({'uid': 'x'});
      expect(user.uid, 'x');
      expect(user.email, '');
      expect(user.currentStreak, 0);
      expect(user.isNewUser, true);
      expect(user.friends, isEmpty);
    });

    test('fromMap gère tutorial_seen null', () {
      final user = UserModel.fromMap({'uid': 'x', 'tutorial_seen': null});
      expect(user.tutorialSeen.dressing, false);
    });

    test('toMap contient tous les champs attendus', () {
      final user = UserModel.fromMap(fullMap);
      final map = user.toMap();
      expect(map['uid'], 'uid-123');
      expect(map['email'], 'test@example.com');
      expect(map['current_streak'], 5);
      expect(map['is_new_user'], false);
      expect(map['friends'], ['uid-2', 'uid-3']);
      expect(map['tutorial_seen'], isA<Map>());
    });

    test('fromMap → toMap est idempotent', () {
      final user = UserModel.fromMap(fullMap);
      final map = user.toMap();
      final user2 = UserModel.fromMap(map);
      expect(user2.uid, user.uid);
      expect(user2.currentStreak, user.currentStreak);
      expect(user2.friends, user.friends);
    });

    test('copyWith ne modifie que les champs spécifiés', () {
      const user = UserModel(uid: 'u1', currentStreak: 3, isNewUser: true);
      final copy = user.copyWith(currentStreak: 7, isNewUser: false);
      expect(copy.uid, 'u1');
      expect(copy.currentStreak, 7);
      expect(copy.isNewUser, false);
    });

    test('isFriendWith retourne true si uid dans la liste', () {
      const user = UserModel(friends: ['uid-2', 'uid-3']);
      expect(user.isFriendWith('uid-2'), true);
      expect(user.isFriendWith('uid-99'), false);
    });

    test('isFriendWith retourne false pour liste vide', () {
      const user = UserModel();
      expect(user.isFriendWith('anyone'), false);
    });
  });
}
