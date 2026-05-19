import 'package:flutter/material.dart';

class GarmentCategory {
  final String key;
  final String label;

  const GarmentCategory({
    required this.key,
    required this.label,
  });
}

const categories = [
  GarmentCategory(key: 'headwear', label: 'Couvre-chef'),
  GarmentCategory(key: 'top', label: 'Hauts'),
  GarmentCategory(key: 'outerwear', label: 'Vestes'),
  GarmentCategory(key: 'bottom', label: 'Bas'),
  GarmentCategory(key: 'shoes', label: 'Chaussures'),
  GarmentCategory(key: 'accessory', label: 'Accessoires'),
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
  return categories
      .firstWhere(
        (c) => c.key == key,
        orElse: () => const GarmentCategory(key: '', label: ''),
      )
      .label;
}
