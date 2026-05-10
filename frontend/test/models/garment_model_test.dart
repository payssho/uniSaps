import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/models/garment_model.dart';

void main() {
  group('GarmentModel', () {
    final fullMap = {
      'user_id': 'uid-1',
      'name': 'T-Shirt Blanc',
      'brand': 'Nike',
      'colors': ['Blanc', 'Gris'],
      'category': 'top',
      'image_url': 'https://img.url/tshirt.jpg',
      'created_at': '2026-01-01T00:00:00.000Z',
      'times_worn': 3,
      'style_tags': ['casual', 'sport'],
      'formality': 'casual',
      'season': 'été',
      'pattern': 'uni',
      'material': 'coton',
    };

    // ── fromMap ──────────────────────────────────────────────────────────────

    test('fromMap lit le nouveau format colors (List)', () {
      final g = GarmentModel.fromMap(fullMap, docId: 'g-1');
      expect(g.id, 'g-1');
      expect(g.userId, 'uid-1');
      expect(g.name, 'T-Shirt Blanc');
      expect(g.brand, 'Nike');
      expect(g.colors, ['Blanc', 'Gris']);
      expect(g.category, 'top');
      expect(g.imageUrls, ['https://img.url/tshirt.jpg']);
      expect(g.imageUrl, 'https://img.url/tshirt.jpg');
      expect(g.timesWorn, 3);
      expect(g.styleTags, ['casual', 'sport']);
      expect(g.formality, 'casual');
      expect(g.season, 'été');
    });

    test('fromMap migre l\'ancien format color (String) → colors', () {
      final g = GarmentModel.fromMap({
        'user_id': 'uid-1',
        'name': 'Jean',
        'brand': 'Levi\'s',
        'color': 'Bleu',  // ancien format
        'category': 'bottom',
        'image_url': '',
        'created_at': '',
        'times_worn': 0,
      }, docId: 'g-old');

      expect(g.colors, ['Bleu']);
      expect(g.color, 'Bleu');
    });

    test('fromMap priorise colors sur color si les deux présents', () {
      final g = GarmentModel.fromMap({
        ...fullMap,
        'color': 'Rouge',   // ancien format (ignoré si colors existe)
        'colors': ['Blanc', 'Noir'],
      });
      expect(g.colors, ['Blanc', 'Noir']);
    });

    test('fromMap gère colors null → liste vide', () {
      final g = GarmentModel.fromMap({
        'user_id': 'uid-1',
        'name': 'Robe',
        'colors': null,
        'color': null,
      });
      expect(g.colors, isEmpty);
    });

    test('fromMap gère champs manquants avec valeurs par défaut', () {
      final g = GarmentModel.fromMap({});
      expect(g.id, '');
      expect(g.userId, '');
      expect(g.name, '');
      expect(g.timesWorn, 0);
      expect(g.colors, isEmpty);
      expect(g.styleTags, isEmpty);
    });

    test('fromMap utilise docId si id absent de la map', () {
      final g = GarmentModel.fromMap({'user_id': 'u'}, docId: 'injected-id');
      expect(g.id, 'injected-id');
    });

    // ── getter color ─────────────────────────────────────────────────────────

    test('getter color retourne le premier élément de colors', () {
      const g = GarmentModel(colors: ['Rouge', 'Blanc']);
      expect(g.color, 'Rouge');
    });

    test('getter color retourne chaîne vide si colors vide', () {
      const g = GarmentModel(colors: []);
      expect(g.color, '');
    });

    // ── toMap ────────────────────────────────────────────────────────────────

    test('toMap contient les deux formats colors et color', () {
      const g = GarmentModel(colors: ['Noir', 'Blanc'], userId: 'u');
      final map = g.toMap();
      expect(map['colors'], ['Noir', 'Blanc']);
      expect(map['color'], 'Noir');  // compatibilité
    });

    test('toMap contient tous les champs attendus', () {
      final g = GarmentModel.fromMap(fullMap, docId: 'g-1');
      final map = g.toMap();
      expect(map['user_id'], 'uid-1');
      expect(map['name'], 'T-Shirt Blanc');
      expect(map['brand'], 'Nike');
      expect(map['category'], 'top');
      expect(map['times_worn'], 3);
      expect(map['style_tags'], ['casual', 'sport']);
    });

    // ── idempotence fromMap → toMap ───────────────────────────────────────────

    test('fromMap → toMap → fromMap est idempotent', () {
      final g1 = GarmentModel.fromMap(fullMap, docId: 'g-1');
      final g2 = GarmentModel.fromMap(g1.toMap(), docId: 'g-1');
      expect(g2.name, g1.name);
      expect(g2.colors, g1.colors);
      expect(g2.timesWorn, g1.timesWorn);
      expect(g2.styleTags, g1.styleTags);
    });

    // ── copyWith ─────────────────────────────────────────────────────────────

    test('copyWith ne modifie que les champs spécifiés', () {
      const g = GarmentModel(name: 'Original', timesWorn: 2, colors: ['Blanc']);
      final copy = g.copyWith(name: 'Modifié', timesWorn: 5);
      expect(copy.name, 'Modifié');
      expect(copy.timesWorn, 5);
      expect(copy.colors, ['Blanc']);
    });

    test('copyWith sans argument retourne une copie identique', () {
      const g = GarmentModel(name: 'Test', colors: ['Bleu'], timesWorn: 1);
      final copy = g.copyWith();
      expect(copy.name, g.name);
      expect(copy.colors, g.colors);
      expect(copy.timesWorn, g.timesWorn);
    });
  });
}
