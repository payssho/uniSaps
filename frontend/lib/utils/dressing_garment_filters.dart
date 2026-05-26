import '../models/garment_model.dart';

/// Filtres locaux nom / marque / couleur (onglet Dressing, catégorie sélectionnée).
List<GarmentModel> applyDressingGarmentFilters({
  required List<GarmentModel> list,
  required String nameFilter,
  required String brandFilter,
  required String colorFilter,
}) {
  final brandLc = brandFilter.trim().toLowerCase();
  final brandExists = brandLc.isNotEmpty &&
      list.any((x) => x.brand.trim().toLowerCase() == brandLc);

  final colorLc = colorFilter.trim().toLowerCase();
  final colorExists = colorLc.isNotEmpty &&
      list.any((x) => x.colors.any((c) => c.trim().toLowerCase() == colorLc));

  return list.where((g) {
    final q = nameFilter.trim().toLowerCase();
    if (q.isNotEmpty && !g.name.toLowerCase().contains(q)) {
      return false;
    }
    if (brandExists && g.brand.trim().toLowerCase() != brandLc) {
      return false;
    }
    if (colorExists &&
        !g.colors.any((c) => c.trim().toLowerCase() == colorLc)) {
      return false;
    }
    return true;
  }).toList();
}
