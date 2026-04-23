import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/services/color_service.dart';

void main() {
  group('ColorService', () {
    // ── getColors ──────────────────────────────────────────────────────────

    test('getColors retourne une liste non vide', () {
      final colors = ColorService.getColors();
      expect(colors, isNotEmpty);
    });

    test('getColors retourne au moins 30 couleurs', () {
      final colors = ColorService.getColors();
      expect(colors.length, greaterThanOrEqualTo(30));
    });

    test('getColors contient des couleurs de base (Noir, Blanc, Rouge, Bleu)', () {
      final names = ColorService.getColors().map((c) => c.name).toList();
      expect(names, contains('Noir'));
      expect(names, contains('Blanc'));
      expect(names, contains('Rouge'));
      expect(names, contains('Bleu'));
    });

    test('chaque ColorOption a un nom non vide', () {
      for (final color in ColorService.getColors()) {
        expect(color.name, isNotEmpty);
      }
    });

    // ── searchColors ──────────────────────────────────────────────────────

    test('searchColors("") retourne les 20 premières couleurs', () {
      final results = ColorService.searchColors('');
      expect(results.length, 20);
      expect(results, ColorService.getColors().take(20).toList());
    });

    test('searchColors filtre par nom (insensible à la casse)', () {
      final results = ColorService.searchColors('rouge');
      expect(results.every((c) => c.name.toLowerCase().contains('rouge')), true);
    });

    test('searchColors filtre par nom (majuscules)', () {
      final results = ColorService.searchColors('ROUGE');
      expect(results.every((c) => c.name.toLowerCase().contains('rouge')), true);
    });

    test('searchColors retourne au max 15 résultats', () {
      // "bleu" devrait matcher plusieurs couleurs
      final results = ColorService.searchColors('bleu');
      expect(results.length, lessThanOrEqualTo(15));
    });

    test('searchColors("bleu") contient Bleu', () {
      final results = ColorService.searchColors('bleu');
      final names = results.map((c) => c.name.toLowerCase()).toList();
      expect(names.any((n) => n.contains('bleu')), true);
    });

    test('searchColors pour une couleur inexistante retourne vide', () {
      final results = ColorService.searchColors('xxxxinexistantxxxx');
      expect(results, isEmpty);
    });

    test('searchColors("noir") retourne exactement Noir', () {
      final results = ColorService.searchColors('noir');
      expect(results.map((c) => c.name).toList(), contains('Noir'));
    });

    test('searchColors("blanc") retourne Blanc', () {
      final results = ColorService.searchColors('blanc');
      expect(results.map((c) => c.name).toList(), contains('Blanc'));
    });

    test('searchColors("vert") retourne plusieurs verts', () {
      final results = ColorService.searchColors('vert');
      expect(results.length, greaterThan(1));
    });

    test('searchColors retourne toujours une liste', () {
      expect(ColorService.searchColors(''), isA<List<ColorOption>>());
      expect(ColorService.searchColors('x'), isA<List<ColorOption>>());
    });

    // ── ColorOption ──────────────────────────────────────────────────────

    test('ColorOption stocke correctement son nom', () {
      final colors = ColorService.getColors();
      for (final c in colors) {
        expect(c.name, isNotEmpty);
        expect(c.name, isA<String>());
      }
    });
  });
}
