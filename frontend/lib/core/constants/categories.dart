import '../../l10n/domain_l10n.dart';
import '../../l10n/generated/app_localizations.dart';

class GarmentCategory {
  final String key;
  final String label;

  const GarmentCategory({
    required this.key,
    required this.label,
  });
}

const categories = [
  GarmentCategory(key: 'headwear', label: 'headwear'),
  GarmentCategory(key: 'top', label: 'top'),
  GarmentCategory(key: 'outerwear', label: 'outerwear'),
  GarmentCategory(key: 'bottom', label: 'bottom'),
  GarmentCategory(key: 'shoes', label: 'shoes'),
  GarmentCategory(key: 'accessory', label: 'accessory'),
];

const categoryKeys = [
  'headwear',
  'top',
  'outerwear',
  'bottom',
  'shoes',
  'accessory',
];

const bodyZones = {
  'head': 'headwear',
  'torso': 'top',
  'jacket': 'outerwear',
  'legs': 'bottom',
  'feet': 'shoes',
  'wrist': 'accessory',
};

/// Canonical style keys sent to the API (labels via [styleLabelL10n]).
const stylePromptKeys = [
  'simple',
  'colorful',
  'classy',
  'professional',
  'casual',
  'streetwear',
  'sporty',
  'evening',
];

/// Legacy French prompts kept for API backward compatibility.
const stylePrompts = [
  'Simple',
  'Coloré',
  'Classe',
  'Professionnel',
  'Décontracté',
  'Streetwear',
  'Sportif',
  'Soirée',
];

String categoryLabel(String key, AppLocalizations l) =>
    categoryLabelL10n(l, key);

String styleLabelL10n(AppLocalizations l, String key) {
  switch (key) {
    case 'simple':
      return l.styleSimple;
    case 'colorful':
      return l.styleColorful;
    case 'classy':
      return l.styleClassy;
    case 'professional':
      return l.styleProfessional;
    case 'casual':
      return l.styleCasual;
    case 'streetwear':
      return l.styleStreetwear;
    case 'sporty':
      return l.styleSporty;
    case 'evening':
      return l.styleEvening;
    default:
      return key;
  }
}
