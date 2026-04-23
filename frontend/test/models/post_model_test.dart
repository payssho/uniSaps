import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/models/post_model.dart';

void main() {
  // ── GarmentRef ─────────────────────────────────────────────────────────────

  group('GarmentRef', () {
    test('valeurs par défaut sont des chaînes vides', () {
      const ref = GarmentRef();
      expect(ref.name, '');
      expect(ref.brand, '');
    });

    test('fromMap lit les champs', () {
      final ref = GarmentRef.fromMap({'name': 'T-Shirt', 'brand': 'Nike'});
      expect(ref.name, 'T-Shirt');
      expect(ref.brand, 'Nike');
    });

    test('fromMap gère les champs manquants', () {
      final ref = GarmentRef.fromMap({});
      expect(ref.name, '');
      expect(ref.brand, '');
    });

    test('toMap retourne les bons champs', () {
      const ref = GarmentRef(name: 'Jean', brand: 'Levi\'s');
      final map = ref.toMap();
      expect(map['name'], 'Jean');
      expect(map['brand'], 'Levi\'s');
    });

    test('fromMap → toMap est idempotent', () {
      final map = {'name': 'Robe', 'brand': 'Zara'};
      final result = GarmentRef.fromMap(map).toMap();
      expect(result, map);
    });
  });

  // ── PostModel ──────────────────────────────────────────────────────────────

  group('PostModel', () {
    final fullMap = {
      'user_id': 'uid-1',
      'username': 'testuser',
      'user_photo_url': 'https://photo.url',
      'image_url': 'https://post.url/img.jpg',
      'outfit_id': 'outfit-1',
      'garment_refs': [
        {'name': 'T-Shirt', 'brand': 'Nike'},
        {'name': 'Jean', 'brand': 'Levi\'s'},
      ],
      'caption': 'Mon look du jour',
      'likes': 12,
      'liked_by': ['uid-2', 'uid-3'],
      'created_at': '2026-01-01T00:00:00.000Z',
    };

    test('valeurs par défaut correctes', () {
      const post = PostModel();
      expect(post.id, '');
      expect(post.userId, '');
      expect(post.likes, 0);
      expect(post.likedBy, isEmpty);
      expect(post.garmentRefs, isEmpty);
    });

    test('fromMap lit tous les champs', () {
      final post = PostModel.fromMap(fullMap, docId: 'post-1');
      expect(post.id, 'post-1');
      expect(post.userId, 'uid-1');
      expect(post.username, 'testuser');
      expect(post.imageUrl, 'https://post.url/img.jpg');
      expect(post.outfitId, 'outfit-1');
      expect(post.caption, 'Mon look du jour');
      expect(post.likes, 12);
      expect(post.likedBy, ['uid-2', 'uid-3']);
      expect(post.garmentRefs, hasLength(2));
      expect(post.garmentRefs[0].name, 'T-Shirt');
      expect(post.garmentRefs[1].brand, 'Levi\'s');
    });

    test('fromMap gère garment_refs null → liste vide', () {
      final post = PostModel.fromMap({'garment_refs': null});
      expect(post.garmentRefs, isEmpty);
    });

    test('fromMap gère garment_refs vide', () {
      final post = PostModel.fromMap({'garment_refs': []});
      expect(post.garmentRefs, isEmpty);
    });

    test('fromMap gère les champs manquants', () {
      final post = PostModel.fromMap({});
      expect(post.id, '');
      expect(post.likes, 0);
      expect(post.likedBy, isEmpty);
    });

    test('fromMap utilise docId si id absent', () {
      final post = PostModel.fromMap({}, docId: 'injected');
      expect(post.id, 'injected');
    });

    test('toMap contient tous les champs', () {
      final post = PostModel.fromMap(fullMap, docId: 'post-1');
      final map = post.toMap();
      expect(map['user_id'], 'uid-1');
      expect(map['username'], 'testuser');
      expect(map['likes'], 12);
      expect(map['liked_by'], ['uid-2', 'uid-3']);
      expect(map['garment_refs'], isA<List>());
      expect((map['garment_refs'] as List).length, 2);
    });

    test('fromMap → toMap → fromMap est idempotent', () {
      final p1 = PostModel.fromMap(fullMap, docId: 'p-1');
      final p2 = PostModel.fromMap(p1.toMap(), docId: 'p-1');
      expect(p2.username, p1.username);
      expect(p2.likes, p1.likes);
      expect(p2.likedBy, p1.likedBy);
      expect(p2.garmentRefs.length, p1.garmentRefs.length);
    });

    // ── isLikedBy ─────────────────────────────────────────────────────────────

    test('isLikedBy retourne true si uid dans likedBy', () {
      const post = PostModel(likedBy: ['uid-1', 'uid-2']);
      expect(post.isLikedBy('uid-1'), true);
      expect(post.isLikedBy('uid-99'), false);
    });

    test('isLikedBy retourne false pour liste vide', () {
      const post = PostModel(likedBy: []);
      expect(post.isLikedBy('anyone'), false);
    });
  });
}
