import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/services/brand_service.dart';

void main() {
  // Note : BrandService.getBrands() charge un asset JSON, ce qui nécessite
  // un TestWidgetsFlutterBinding et un rootBundle réel.
  // On teste ici la logique pure de searchBrands.

  group('BrandService.searchBrands', () {
    const brands = [
      'Nike',
      'Adidas',
      'Puma',
      'Zara',
      'H&M',
      'Uniqlo',
      'New Balance',
      'Levi\'s',
      'Ralph Lauren',
      'Tommy Hilfiger',
      'Calvin Klein',
    ];

    test('requête vide retourne liste vide', () {
      final results = BrandService.searchBrands('', brands);
      expect(results, isEmpty);
    });

    test('requête partielle trouve les correspondances', () {
      final results = BrandService.searchBrands('nik', brands);
      expect(results, contains('Nike'));
    });

    test('requête insensible à la casse', () {
      final results = BrandService.searchBrands('NIKE', brands);
      expect(results, contains('Nike'));
    });

    test('requête insensible à la casse (minuscules)', () {
      final results = BrandService.searchBrands('adidas', brands);
      expect(results, contains('Adidas'));
    });

    test('requête partielle au milieu du nom', () {
      final results = BrandService.searchBrands('balan', brands);
      expect(results, contains('New Balance'));
    });

    test('retourne au max 10 résultats', () {
      // Créer une liste avec plus de 10 marques contenant "a"
      final manyBrands = List.generate(20, (i) => 'Brand-A-$i');
      final results = BrandService.searchBrands('a', manyBrands);
      expect(results.length, lessThanOrEqualTo(10));
    });

    test('requête inexistante retourne liste vide', () {
      final results = BrandService.searchBrands('xxxyyyzzz', brands);
      expect(results, isEmpty);
    });

    test('trouve des marques avec apostrophe', () {
      final results = BrandService.searchBrands('levi', brands);
      expect(results, contains('Levi\'s'));
    });

    test('trouve des marques avec &', () {
      final results = BrandService.searchBrands('h&', brands);
      expect(results, contains('H&M'));
    });

    test('retourne liste vide si allBrands vide', () {
      final results = BrandService.searchBrands('nike', []);
      expect(results, isEmpty);
    });

    test('résultats sont triés dans l\'ordre de la liste source', () {
      final results = BrandService.searchBrands('a', brands);
      final indices = results.map((r) => brands.indexOf(r)).toList();
      expect(indices, equals([...indices]..sort()));
    });
  });
}
