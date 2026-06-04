import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/garment_model.dart';
import '../services/color_service.dart';
import '../l10n/l10n_context.dart';

/// Barre de filtres nom / marque / couleur (Dressing + profil ami).
class DressingCategoryFiltersBar extends StatelessWidget {
  final TextEditingController nameController;
  final String brandFilter;
  final String colorFilter;
  final List<GarmentModel> garmentsForOptions;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<String?> onColorChanged;

  const DressingCategoryFiltersBar({
    super.key,
    required this.nameController,
    required this.brandFilter,
    required this.colorFilter,
    required this.garmentsForOptions,
    required this.onNameChanged,
    required this.onBrandChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brands = garmentsForOptions
        .map((g) => g.brand.trim())
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final colors = <String>{};
    for (final g in garmentsForOptions) {
      for (final c in g.colors) {
        final t = c.trim();
        if (t.isNotEmpty) colors.add(t);
      }
    }
    final colorList = colors.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final safeBrand = brandFilter.isNotEmpty && !brands.contains(brandFilter)
        ? ''
        : brandFilter;
    final safeColor = colorFilter.isNotEmpty && !colorList.contains(colorFilter)
        ? ''
        : colorFilter;

    const denseStyle = TextStyle(fontSize: 12);
    const hintStyle = TextStyle(fontSize: 11, color: AppColors.textHint);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider.withOpacity(0.55)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: nameController,
                  style: denseStyle,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    hintText: l10n.dressingNameHint,
                    hintStyle: hintStyle,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: AppColors.textHint.withOpacity(0.85),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 30, maxHeight: 28),
                    filled: true,
                    fillColor: AppColors.canvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: onNameChanged,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 92,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: safeBrand.isEmpty ? '' : safeBrand,
                    isDense: true,
                    iconSize: 18,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l10n.dressingFilterBrand, style: denseStyle),
                      ),
                      ...brands.map(
                        (b) => DropdownMenuItem(
                          value: b,
                          child: Text(
                            b,
                            style: denseStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: onBrandChanged,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 92,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: safeColor.isEmpty ? '' : safeColor,
                    isDense: true,
                    iconSize: 18,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l10n.dressingFilterColor, style: denseStyle),
                      ),
                      ...colorList.map(
                        (c) {
                          final swatch = ColorService.getColors()
                              .firstWhere(
                                (opt) =>
                                    opt.name.toLowerCase() == c.toLowerCase(),
                                orElse: () => ColorOption(
                                  name: c,
                                  color: AppColors.textHint,
                                ),
                              )
                              .color;
                          return DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: swatch,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.divider,
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    c,
                                    style: denseStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    onChanged: onColorChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
