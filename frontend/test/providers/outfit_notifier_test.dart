import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/providers/auth_provider.dart';
import 'package:unisaps/providers/outfit_provider.dart';
import '../helpers/fakes.dart';

void main() {
  late FakeFirestoreService fakeDb;
  late ProviderContainer container;

  setUp(() {
    fakeDb = FakeFirestoreService();
    container = ProviderContainer(overrides: [
      firestoreServiceProvider.overrideWithValue(fakeDb),
    ]);
  });

  tearDown(() => container.dispose());

  OutfitNotifier n() => container.read(outfitNotifierProvider.notifier);

  // ── createOutfit ───────────────────────────────────────────────────────────

  group('createOutfit', () {
    test('état initial est AsyncData(null)', () {
      expect(container.read(outfitNotifierProvider).hasValue, true);
    });

    test('succès → retourne un id non null', () async {
      final id = await n().createOutfit(
        userId: 'uid-1',
        name: 'Look été',
        garments: {'top': 'g-1', 'bottom': 'g-2'},
      );
      expect(id, isNotNull);
      expect(id, isNotEmpty);
    });

    test('succès → état final est AsyncData(null)', () async {
      await n().createOutfit(userId: 'uid-1', name: 'Look hiver', garments: {});
      expect(container.read(outfitNotifierProvider).hasValue, true);
      expect(container.read(outfitNotifierProvider).hasError, false);
    });

    test('succès → l\'outfit est ajouté dans le fake DB', () async {
      await n().createOutfit(userId: 'uid-1', name: 'Mon Outfit', garments: {'top': 'g-1'});
      expect(fakeDb.outfits['uid-1'], isNotEmpty);
      expect(fakeDb.outfits['uid-1']!.first.name, 'Mon Outfit');
    });

    test('erreur → état final est AsyncError', () async {
      fakeDb.nextError = Exception('Erreur Firestore');
      final id = await n().createOutfit(userId: 'uid-1', name: 'Fail', garments: {});
      expect(id, isNull);
      expect(container.read(outfitNotifierProvider).hasError, true);
    });

    test('crée plusieurs outfits avec des IDs uniques', () async {
      final id1 = await n().createOutfit(userId: 'uid-1', name: 'A', garments: {});
      final id2 = await n().createOutfit(userId: 'uid-1', name: 'B', garments: {});
      expect(id1, isNot(id2));
    });

    test('referencePhotoUrl est stocké', () async {
      await n().createOutfit(
        userId: 'uid-1',
        name: 'Photo Outfit',
        garments: {},
        referencePhotoUrl: 'https://photo.url',
      );
      expect(fakeDb.outfits['uid-1']!.first.referencePhotoUrl, 'https://photo.url');
    });
  });

  // ── setDailyOutfit ─────────────────────────────────────────────────────────

  group('setDailyOutfit', () {
    setUp(() {
      fakeDb.users['uid-1'] = fakeUser(uid: 'uid-1').toMap();
      fakeDb.outfits['uid-1'] = [fakeOutfit(id: 'outfit-1', userId: 'uid-1')];
    });

    test('met à jour daily_outfit_id sur l\'user', () async {
      await n().setDailyOutfit('uid-1', 'outfit-1');
      expect(fakeDb.users['uid-1']!['daily_outfit_id'], 'outfit-1');
    });

    test('met à jour daily_outfit_date avec la date du jour', () async {
      await n().setDailyOutfit('uid-1', 'outfit-1');
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(fakeDb.users['uid-1']!['daily_outfit_date'], today);
    });

    test('incrémente times_worn sur l\'outfit', () async {
      final before = fakeDb.outfits['uid-1']!.first.timesWorn;
      await n().setDailyOutfit('uid-1', 'outfit-1');
      final after = fakeDb.outfits['uid-1']!.first.timesWorn;
      expect(after, before + 1);
    });

    test(
        'changement du fit le même jour : -1 sur l’ancien, +1 sur le nouveau',
        () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      fakeDb.outfits['uid-1'] = [
        fakeOutfit(id: 'outfit-1', userId: 'uid-1', timesWorn: 3),
        fakeOutfit(id: 'outfit-2', userId: 'uid-1', name: 'B', timesWorn: 1),
      ];
      fakeDb.users['uid-1'] = {
        ...fakeUser(uid: 'uid-1', dailyOutfitId: 'outfit-1').toMap(),
        'daily_outfit_date': today,
      };

      await n().setDailyOutfit('uid-1', 'outfit-2');

      final after1 =
          fakeDb.outfits['uid-1']!.firstWhere((o) => o.id == 'outfit-1').timesWorn;
      final after2 =
          fakeDb.outfits['uid-1']!.firstWhere((o) => o.id == 'outfit-2').timesWorn;
      expect(after1, 2);
      expect(after2, 2);
    });

    test('re-sélection du même outfit le même jour → pas de nouveau +1',
        () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      fakeDb.outfits['uid-1'] = [
        fakeOutfit(id: 'outfit-1', userId: 'uid-1', timesWorn: 1),
      ];
      fakeDb.users['uid-1'] = {
        ...fakeUser(uid: 'uid-1', dailyOutfitId: 'outfit-1').toMap(),
        'daily_outfit_date': today,
      };

      await n().setDailyOutfit('uid-1', 'outfit-1');
      expect(fakeDb.outfits['uid-1']!.first.timesWorn, 1);
    });
  });

  // ── clearDailyOutfit ───────────────────────────────────────────────────────

  group('clearDailyOutfit', () {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    setUp(() {
      fakeDb.users['uid-1'] = {
        ...fakeUser(uid: 'uid-1', dailyOutfitId: 'outfit-1').toMap(),
        'daily_outfit_date': today,
      };
      fakeDb.outfits['uid-1'] = [
        fakeOutfit(id: 'outfit-1', userId: 'uid-1', timesWorn: 5),
      ];
    });

    test('vide daily_outfit_id sur l\'user', () async {
      await n().clearDailyOutfit('uid-1');
      expect(fakeDb.users['uid-1']!['daily_outfit_id'], '');
    });

    test('vide daily_photo_url sur l\'user', () async {
      fakeDb.users['uid-1']!['daily_photo_url'] = 'https://photo.url';
      await n().clearDailyOutfit('uid-1');
      expect(fakeDb.users['uid-1']!['daily_photo_url'], '');
    });

    test('annule le +1 du jour sur l\'outfit quotidien', () async {
      await n().clearDailyOutfit('uid-1');
      expect(
        fakeDb.outfits['uid-1']!.first.timesWorn,
        4,
      );
    });
  });

  // ── deleteOutfit ───────────────────────────────────────────────────────────

  group('deleteOutfit', () {
    setUp(() {
      fakeDb.outfits['uid-1'] = [
        fakeOutfit(id: 'outfit-1', userId: 'uid-1'),
        fakeOutfit(id: 'outfit-2', userId: 'uid-1', name: 'Outfit 2'),
      ];
    });

    test('supprime l\'outfit de la DB', () async {
      await n().deleteOutfit('uid-1', 'outfit-1');
      expect(fakeDb.outfits['uid-1']!.any((o) => o.id == 'outfit-1'), false);
    });

    test('ne supprime que l\'outfit ciblé', () async {
      await n().deleteOutfit('uid-1', 'outfit-1');
      expect(fakeDb.outfits['uid-1']!.any((o) => o.id == 'outfit-2'), true);
    });
  });

  // ── setDailyPhoto ──────────────────────────────────────────────────────────

  group('setDailyPhoto', () {
    setUp(() {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      fakeDb.users['uid-1'] = {
        ...fakeUser(uid: 'uid-1', dailyOutfitId: 'outfit-1').toMap(),
        'daily_outfit_date': today,
        'daily_photo_url': '',
      };
      fakeDb.outfits['uid-1'] = [fakeOutfit(id: 'outfit-1', userId: 'uid-1')];
    });

    test('met à jour daily_photo_url sur l\'user', () async {
      await n().setDailyPhoto('uid-1', 'outfit-1', 'https://new-photo.url');
      expect(fakeDb.users['uid-1']!['daily_photo_url'], 'https://new-photo.url');
    });
  });
}
