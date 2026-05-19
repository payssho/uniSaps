import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ColorService {
  static final List<ColorOption> _colors = [
    const ColorOption(name: 'Noir', color: AppColors.graphite),
    const ColorOption(name: 'Blanc', color: AppColors.white),
    const ColorOption(name: 'Gris', color: AppColors.alabasterGrey),
    const ColorOption(name: 'Gris clair', color: AppColors.alabasterGrey),
    const ColorOption(name: 'Gris foncé', color: AppColors.graphite),
    const ColorOption(name: 'Beige', color: Color(0xFFF5F5DC)),
    const ColorOption(name: 'Camel', color: Color(0xFFC19A6B)),
    const ColorOption(name: 'Marron', color: Colors.brown),
    ColorOption(name: 'Marron clair', color: Colors.brown.shade300),
    ColorOption(name: 'Marron foncé', color: Colors.brown.shade700),
    const ColorOption(name: 'Bleu', color: AppColors.yaleBlue),
    const ColorOption(name: 'Bleu clair', color: AppColors.stormyTeal),
    const ColorOption(name: 'Bleu foncé', color: AppColors.graphite),
    const ColorOption(name: 'Bleu marine', color: Color(0xFF000080)),
    const ColorOption(name: 'Bleu ciel', color: Color(0xFF87CEEB)),
    const ColorOption(name: 'Bleu turquoise', color: AppColors.stormyTeal),
    const ColorOption(name: 'Rouge', color: Colors.red),
    ColorOption(name: 'Rouge foncé', color: Colors.red.shade700),
    const ColorOption(name: 'Rouge bordeaux', color: Color(0xFF800020)),
    const ColorOption(name: 'Rose', color: Colors.pink),
    ColorOption(name: 'Rose poudré', color: Colors.pink.shade200),
    const ColorOption(name: 'Rose fuchsia', color: Colors.pinkAccent),
    const ColorOption(name: 'Vert', color: Colors.green),
    ColorOption(name: 'Vert clair', color: Colors.green.shade300),
    ColorOption(name: 'Vert foncé', color: Colors.green.shade700),
    ColorOption(name: 'Vert menthe', color: Colors.teal.shade300),
    const ColorOption(name: 'Vert kaki', color: Color(0xFF6B8E23)),
    ColorOption(name: 'Jaune', color: Colors.yellow.shade600),
    const ColorOption(name: 'Jaune moutarde', color: Color(0xFFFFDB58)),
    const ColorOption(name: 'Orange', color: Colors.orange),
    ColorOption(name: 'Orange corail', color: Colors.deepOrange.shade300),
    const ColorOption(name: 'Violet', color: Colors.purple),
    ColorOption(name: 'Violet foncé', color: Colors.purple.shade700),
    ColorOption(name: 'Lavande', color: Colors.purple.shade300),
    const ColorOption(name: 'Bordeaux', color: Color(0xFF800020)),
    const ColorOption(name: 'Burgundy', color: Color(0xFF800020)),
    const ColorOption(name: 'Navy', color: Color(0xFF000080)),
    const ColorOption(name: 'Khaki', color: Color(0xFFC3B091)),
    const ColorOption(name: 'Olive', color: Color(0xFF808000)),
    const ColorOption(name: 'Sable', color: Color(0xFFF4A460)),
    const ColorOption(name: 'Crème', color: Color(0xFFFFFDD0)),
    const ColorOption(name: 'Ivoire', color: Color(0xFFFFFFF0)),
    const ColorOption(name: 'Écru', color: Color(0xFFF5F5DC)),
    const ColorOption(name: 'Taupe', color: Color(0xFF8B7355)),
    const ColorOption(name: 'Charbon', color: Color(0xFF36454F)),
    const ColorOption(name: 'Anthracite', color: Color(0xFF383838)),
    const ColorOption(name: 'Nude', color: Color(0xFFE3C9A6)),
    const ColorOption(name: 'Pêche', color: Color(0xFFFFCBA4)),
    const ColorOption(name: 'Corail', color: Color(0xFFFF7F50)),
    const ColorOption(name: 'Saumon', color: Color(0xFFFF8C69)),
    const ColorOption(name: 'Terracotta', color: Color(0xFFE2725B)),
    const ColorOption(name: 'Rouille', color: Color(0xFFB7410E)),
    const ColorOption(name: 'Brique', color: Color(0xFF8B4513)),
    const ColorOption(name: 'Caramel', color: Color(0xFFD2691E)),
    const ColorOption(name: 'Cognac', color: Color(0xFF9F4636)),
    const ColorOption(name: 'Champagne', color: Color(0xFFF7E7CE)),
    const ColorOption(name: 'Doré', color: Color(0xFFFFD700)),
    const ColorOption(name: 'Cuivre', color: Color(0xFFB87333)),
    const ColorOption(name: 'Bronze', color: Color(0xFFCD7F32)),
    const ColorOption(name: 'Argent', color: Color(0xFFC0C0C0)),
    const ColorOption(name: 'Métallique', color: Color(0xFFA8A8A8)),
    const ColorOption(name: 'Multicolore', color: Colors.transparent),
  ];

  /// Une entrée par famille (pas Bleu + Bleu clair + marine ; la recherche garde les nuances).
  static const List<String> _quickPickColorNames = [
    'Noir',
    'Blanc',
    'Bleu',
    'Rouge',
    'Vert',
    'Jaune',
    'Orange',
    'Rose',
    'Violet',
    'Marron',
    'Beige',
    'Gris',
    'Multicolore',
  ];

  static List<ColorOption> getColors() => _colors;

  /// Couleurs simples les plus utiles en premier (pas les nuances de gris, etc.).
  static List<ColorOption> quickPickColors() {
    final byLower = <String, ColorOption>{};
    for (final c in _colors) {
      byLower.putIfAbsent(c.name.toLowerCase(), () => c);
    }
    final out = <ColorOption>[];
    for (final name in _quickPickColorNames) {
      final found = byLower[name.toLowerCase()];
      if (found != null) out.add(found);
    }
    return out;
  }

  static List<ColorOption> searchColors(String query) {
    if (query.isEmpty) return quickPickColors();
    
    final lowerQuery = query.toLowerCase();
    return _colors
        .where((color) => color.name.toLowerCase().contains(lowerQuery))
        .take(15)
        .toList();
  }
}

class ColorOption {
  final String name;
  final Color color;

  const ColorOption({
    required this.name,
    required this.color,
  });
}
