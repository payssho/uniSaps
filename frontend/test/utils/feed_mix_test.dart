import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/models/post_model.dart';
import 'package:unisaps/utils/feed_mix.dart';

void main() {
  PostModel organic(String isoDate, {String id = ''}) => PostModel(
        id: id.isNotEmpty ? id : isoDate,
        userId: 'u1',
        createdAt: isoDate,
        postKind: 'organic',
      );

  PostModel sponsored(String isoDate, {String id = ''}) => PostModel(
        id: id.isNotEmpty ? id : 's-$isoDate',
        userId: 'brand',
        createdAt: isoDate,
        postKind: 'sponsored',
        isSponsored: true,
        isActive: true,
      );

  group('mixExploreFeed', () {
    test('sans sponsorisés retourne les organiques triés par date décroissante', () {
      final result = mixExploreFeed(
        organic: [
          organic('2026-01-01T10:00:00.000Z', id: 'a'),
          organic('2026-01-03T12:00:00.000Z', id: 'c'),
          organic('2026-01-02T11:00:00.000Z', id: 'b'),
        ],
        sponsoredActive: [],
      );
      expect(result.first.id, 'c');
      expect(result.last.id, 'a');
      expect(result.length, 3);
    });

    test('insère un sponsorisé tous les N organiques', () {
      final organics = List.generate(
        7,
        (i) => organic('2026-01-${(i + 1).toString().padLeft(2, '0')}T12:00:00Z'),
      );
      final sponsors = [
        sponsored('2026-02-01T12:00:00Z'),
        sponsored('2026-02-02T12:00:00Z'),
      ];
      final result = mixExploreFeed(
        organic: organics,
        sponsoredActive: sponsors,
        organicInterval: 7,
      );
      expect(result.length, 8);
      expect(result[7].isSponsored, true);
    });

    test('sans multiple de N organiques : aucune insertion sponsorisée', () {
      final result = mixExploreFeed(
        organic: [organic('2026-01-01T12:00:00Z', id: 'only')],
        sponsoredActive: [
          sponsored('2026-02-01T12:00:00Z', id: 'sp1'),
          sponsored('2026-02-02T12:00:00Z', id: 'sp2'),
        ],
        organicInterval: 7,
      );
      expect(result.length, 1);
      expect(result.first.id, 'only');
      expect(result.every((p) => !p.isSponsored), true);
    });

    test('rotation infinie des sponsorisés après chaque bloc de N organiques', () {
      final organics = List.generate(
        21,
        (i) => organic(
          '2026-01-${(i + 1).toString().padLeft(2, '0')}T12:00:00Z',
          id: 'day${i + 1}',
        ),
      );
      final sponsors = [
        sponsored('2026-02-02T12:00:00Z', id: 'sp-B'),
        sponsored('2026-02-01T12:00:00Z', id: 'sp-A'),
      ];
      final result = mixExploreFeed(
        organic: organics,
        sponsoredActive: sponsors,
        organicInterval: 7,
      );
      expect(result.length, 24);
      expect(result[7].id, 'sp-B');
      expect(result[15].id, 'sp-A');
      expect(result[23].id, 'sp-B');
    });
  });
}
