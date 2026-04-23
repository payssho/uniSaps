import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/models/outfit_model.dart';

void main() {
  group('OutfitModel', () {
    final fullMap = {
      'user_id': 'uid-1',
      'name': 'Look casual',
      'garments': {
        'top': 'g-top',
        'bottom': 'g-bottom',
        'shoes': 'g-shoes',
        'outerwear': '',
        'headwear': '',
        'accessory': '',
      },
      'created_at': '2026-01-01T00:00:00.000Z',
      'times_worn': 4,
      'last_worn': '2026-03-01',
      'wear_history': ['2026-01-15', '2026-02-10'],
      'photo_urls': ['https://photo1.url', 'https://photo2.url'],
      'reference_photo_url': 'https://ref.url',
    };

    // ── fromMap ──────────────────────────────────────────────────────────────

    test('fromMap lit tous les champs', () {
      final o = OutfitModel.fromMap(fullMap, docId: 'outfit-1');
      expect(o.id, 'outfit-1');
      expect(o.userId, 'uid-1');
      expect(o.name, 'Look casual');
      expect(o.timesWorn, 4);
      expect(o.lastWorn, '2026-03-01');
      expect(o.wearHistory, ['2026-01-15', '2026-02-10']);
      expect(o.photoUrls, ['https://photo1.url', 'https://photo2.url']);
      expect(o.referencePhotoUrl, 'https://ref.url');
      expect(o.garments['top'], 'g-top');
      expect(o.garments['bottom'], 'g-bottom');
    });

    test('fromMap gère garments null → map vide', () {
      final o = OutfitModel.fromMap({'garments': null});
      expect(o.garments, isEmpty);
    });

    test('fromMap gère garments non-Map → map vide', () {
      final o = OutfitModel.fromMap({'garments': 'invalide'});
      expect(o.garments, isEmpty);
    });

    test('fromMap convertit les valeurs garments en String', () {
      final o = OutfitModel.fromMap({
        'garments': {'top': 42, 'bottom': null},
      });
      expect(o.garments['top'], '42');
      expect(o.garments['bottom'], '');
    });

    test('fromMap gère champs manquants avec valeurs par défaut', () {
      final o = OutfitModel.fromMap({});
      expect(o.id, '');
      expect(o.userId, '');
      expect(o.name, '');
      expect(o.timesWorn, 0);
      expect(o.wearHistory, isEmpty);
      expect(o.photoUrls, isEmpty);
    });

    test('fromMap utilise docId si id absent', () {
      final o = OutfitModel.fromMap({}, docId: 'injected');
      expect(o.id, 'injected');
    });

    // ── toMap ────────────────────────────────────────────────────────────────

    test('toMap contient tous les champs attendus', () {
      final o = OutfitModel.fromMap(fullMap, docId: 'o-1');
      final map = o.toMap();
      expect(map['user_id'], 'uid-1');
      expect(map['name'], 'Look casual');
      expect(map['times_worn'], 4);
      expect(map['last_worn'], '2026-03-01');
      expect(map['wear_history'], ['2026-01-15', '2026-02-10']);
      expect(map['photo_urls'], ['https://photo1.url', 'https://photo2.url']);
      expect(map['garments'], isA<Map>());
    });

    test('fromMap → toMap → fromMap est idempotent', () {
      final o1 = OutfitModel.fromMap(fullMap, docId: 'o-1');
      final o2 = OutfitModel.fromMap(o1.toMap(), docId: 'o-1');
      expect(o2.name, o1.name);
      expect(o2.timesWorn, o1.timesWorn);
      expect(o2.garments, o1.garments);
      expect(o2.photoUrls, o1.photoUrls);
    });

    // ── garmentIds getter ────────────────────────────────────────────────────

    test('garmentIds retourne seulement les IDs non vides', () {
      final o = OutfitModel.fromMap({
        'garments': {
          'top': 'g-top',
          'bottom': '',
          'shoes': 'g-shoes',
          'headwear': '',
        },
      });
      expect(o.garmentIds, containsAll(['g-top', 'g-shoes']));
      expect(o.garmentIds, hasLength(2));
    });

    test('garmentIds retourne liste vide si tous les garments vides', () {
      final o = OutfitModel.fromMap({
        'garments': {'top': '', 'bottom': ''},
      });
      expect(o.garmentIds, isEmpty);
    });

    test('garmentIds retourne liste vide si garments vide', () {
      const o = OutfitModel();
      expect(o.garmentIds, isEmpty);
    });

    // ── copyWith ─────────────────────────────────────────────────────────────

    test('copyWith ne modifie que les champs spécifiés', () {
      const o = OutfitModel(name: 'Original', timesWorn: 2, lastWorn: '2026-01-01');
      final copy = o.copyWith(name: 'Nouveau', timesWorn: 5);
      expect(copy.name, 'Nouveau');
      expect(copy.timesWorn, 5);
      expect(copy.lastWorn, '2026-01-01');
    });

    test('copyWith garments remplace correctement', () {
      const o = OutfitModel(garments: {'top': 'g1'});
      final copy = o.copyWith(garments: {'top': 'g2', 'bottom': 'g3'});
      expect(copy.garments['top'], 'g2');
      expect(copy.garments['bottom'], 'g3');
    });

    test('defaultGarments contient les 6 catégories attendues', () {
      expect(OutfitModel.defaultGarments.keys,
          containsAll(['headwear', 'top', 'outerwear', 'bottom', 'shoes', 'accessory']));
    });
  });
}
