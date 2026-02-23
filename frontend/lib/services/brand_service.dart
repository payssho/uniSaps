import 'dart:convert';
import 'package:flutter/services.dart';

class BrandService {
  static List<String>? _brands;
  
  static Future<List<String>> getBrands() async {
    if (_brands != null) return _brands!;
    
    try {
      final String jsonString = await rootBundle.loadString('assets/data/brand.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _brands = jsonData.keys.toList()..sort();
      return _brands!;
    } catch (e) {
      return [];
    }
  }
  
  static List<String> searchBrands(String query, List<String> allBrands) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return allBrands
        .where((brand) => brand.toLowerCase().contains(lowerQuery))
        .take(10)
        .toList();
  }
}
