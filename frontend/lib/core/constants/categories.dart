import 'package:flutter/material.dart';

class GarmentCategory {
  final String key;
  final String label;
  final IconData icon;

  const GarmentCategory({
    required this.key,
    required this.label,
    required this.icon,
  });
}

const categories = [
  GarmentCategory(key: 'headwear', label: 'Couvre-chef', icon: Icons.face),
  GarmentCategory(key: 'top', label: 'Hauts', icon: Icons.checkroom),
  GarmentCategory(key: 'outerwear', label: 'Vestes', icon: Icons.dry_cleaning),
  GarmentCategory(key: 'bottom', label: 'Bas', icon: Icons.accessibility_new),
  GarmentCategory(key: 'shoes', label: 'Chaussures', icon: Icons.ice_skating),
  GarmentCategory(key: 'accessory', label: 'Accessoires', icon: Icons.watch),
];

const categoryKeys = [
  'headwear', 'top', 'outerwear', 'bottom', 'shoes', 'accessory',
];

const bodyZones = {
  'head': 'headwear',
  'torso': 'top',
  'jacket': 'outerwear',
  'legs': 'bottom',
  'feet': 'shoes',
  'wrist': 'accessory',
};

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

String categoryLabel(String key) {
  return categories.firstWhere(
    (c) => c.key == key,
    orElse: () => const GarmentCategory(key: '', label: '', icon: Icons.help),
  ).label;
}

IconData categoryIcon(String key) {
  return categories.firstWhere(
    (c) => c.key == key,
    orElse: () => const GarmentCategory(key: '', label: '', icon: Icons.help),
  ).icon;
}
