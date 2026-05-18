import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/providers/auth_provider.dart';
import 'package:unisaps/providers/garment_provider.dart';
import '../helpers/fakes.dart';

void main() {
  late FakeFirestoreService fakeDb;
  late FakeStorageService fakeStorage;
  late FakeApiService fakeApi;
  late ProviderContainer container;

  setUp(() {
    fakeDb = FakeFirestoreService();
    fakeStorage = FakeStorageService();
    fakeApi = FakeApiService();
    container = ProviderContainer(overrides: [
      firestoreServiceProvider.overrideWithValue(fakeDb),
      storageServiceProvider.overrideWithValue(fakeStorage),
      apiServiceProvider.overrideWithValue(fakeApi),
    ]);
  });

  tearDown(() => container.dispose());

  GarmentNotifier n() => container.read(garmentNotifierProvider.notifier);

  final fakeBytes = Uint8List.fromList([0, 1, 2, 3]);

  // ── addGarment sans image ──────────────────────────────────────────────────

  group('addGarment sans image', () {
    test('succès → retourne true', () async {
      final ok = await n().addGarment(
        userId: 'uid-1',
        name: 'T-Shirt',
        brand: 'Nike',
        colors: ['Blanc'],
        category: 'top',
      );
      expect(ok, true);
    });

    test('succès → vêtement ajouté dans le fake DB', () async {
      await n().addGarment(
        userId: 'uid-1',
        name: 'Jean Slim',
        brand: 'Levi\'s',
        colors: ['Bleu'],
        category: 'bottom',
      );
      expect(fakeDb.garments['uid-1'], isNotEmpty);
      expect(fakeDb.garments['uid-1']!.first.name, 'Jean Slim');
    });

    test('succès → imageUrl est vide sans image fournie', () async {
      await n().addGarment(
        userId: 'uid-1',
        name: 'Chaussures',
        brand: 'Adidas',
        colors: ['Noir'],
        category: 'shoes',
      );
      expect(fakeDb.garments['uid-1']!.first.imageUrl, '');
    });

    test('succès → état final est AsyncData(null)', () async {
      await n().addGarment(
        userId: 'uid-1',
        name: 'Pull',
        brand: 'Zara',
        colors: ['Gris'],
        category: 'top',
      );
      expect(container.read(garmentNotifierProvider).hasValue, true);
      expect(container.read(garmentNotifierProvider).hasError, false);
    });

    test('erreur Firestore → retourne false et état AsyncError', () async {
      fakeDb.nextError = Exception('Firestore error');
      final ok = await n().addGarment(
        userId: 'uid-1',
        name: 'Fail',
        brand: '',
        colors: [],
        category: '',
      );
      expect(ok, false);
      expect(container.read(garmentNotifierProvider).hasError, true);
    });
  });

  // ── addGarment avec image ──────────────────────────────────────────────────

  group('addGarment avec image', () {
    test('succès → appelle l\'API et stocke l\'imageUrl', () async {
      fakeApi.uploadResult = 'https://cdn.url/garment.png';
      await n().addGarment(
        userId: 'uid-1',
        name: 'Veste',
        brand: 'H&M',
        colors: ['Kaki'],
        category: 'outerwear',
        imageBytesList: [fakeBytes],
        imageNames: ['veste.jpg'],
      );
      expect(fakeDb.garments['uid-1']!.first.imageUrl, 'https://cdn.url/garment.png');
    });

    test('échec API → retourne false', () async {
      fakeApi.nextError = Exception('API down');
      final ok = await n().addGarment(
        userId: 'uid-1',
        name: 'Veste',
        brand: 'H&M',
        colors: ['Kaki'],
        category: 'outerwear',
        imageBytesList: [fakeBytes],
        imageNames: ['veste.jpg'],
      );
      expect(ok, false);
    });

    test('stocke les métadonnées enrichies', () async {
      await n().addGarment(
        userId: 'uid-1',
        name: 'Polo',
        brand: 'Lacoste',
        colors: ['Blanc', 'Vert'],
        category: 'top',
        styleTags: ['casual', 'sport'],
        formality: 'casual',
        season: 'printemps',
        pattern: 'uni',
        material: 'coton',
      );
      final g = fakeDb.garments['uid-1']!.first;
      expect(g.styleTags, ['casual', 'sport']);
      expect(g.formality, 'casual');
      expect(g.season, 'printemps');
    });
  });

  // ── updateGarment ─────────────────────────────────────────────────────────

  group('updateGarment', () {
    setUp(() {
      fakeDb.garments['uid-1'] = [
        fakeGarment(id: 'g-1', userId: 'uid-1', name: 'Original'),
      ];
    });

    test('succès → retourne true', () async {
      final ok = await n().updateGarment(
        uid: 'uid-1',
        garmentId: 'g-1',
        name: 'Modifié',
        brand: 'Nike',
        colors: ['Blanc'],
        category: 'top',
      );
      expect(ok, true);
    });

    test('vêtement inexistant → retourne false', () async {
      final ok = await n().updateGarment(
        uid: 'uid-1',
        garmentId: 'inexistant',
        name: 'X',
        brand: '',
        colors: [],
        category: '',
      );
      expect(ok, false);
    });
  });

  // ── deleteGarment ─────────────────────────────────────────────────────────

  group('deleteGarment', () {
    setUp(() {
      fakeDb.garments['uid-1'] = [
        fakeGarment(id: 'g-1', userId: 'uid-1', imageUrl: 'https://img.url'),
        fakeGarment(id: 'g-2', userId: 'uid-1', name: 'Autre'),
      ];
    });

    test('succès → retourne true', () async {
      final ok = await n().deleteGarment('uid-1', 'g-1');
      expect(ok, true);
    });

    test('supprime le vêtement de la DB', () async {
      await n().deleteGarment('uid-1', 'g-1');
      expect(fakeDb.garments['uid-1']!.any((g) => g.id == 'g-1'), false);
    });

    test('ne supprime que le vêtement ciblé', () async {
      await n().deleteGarment('uid-1', 'g-1');
      expect(fakeDb.garments['uid-1']!.any((g) => g.id == 'g-2'), true);
    });

    test('appelle deleteImage sur StorageService pour l\'image', () async {
      await n().deleteGarment('uid-1', 'g-1');
      expect(fakeStorage.deletedUrls, contains('https://img.url'));
    });

    test('ne plante pas si le vêtement n\'existe pas', () async {
      final ok = await n().deleteGarment('uid-1', 'inexistant');
      expect(ok, true);
    });
  });
}
