class GarmentModel {
  final String id;
  final String userId;
  final String name;
  final String brand;
  final List<String> colors; // Support pour plusieurs couleurs
  final String category;
  /// URLs des photos du vêtement (ordre d’affichage). Ancien champ unique : [image_url].
  final List<String> imageUrls;
  final String createdAt;
  final int timesWorn;
  // Métadonnées enrichies par l'IA (optionnelles)
  final List<String> styleTags;
  final String formality;
  final String season;
  final String pattern;
  final String material;

  const GarmentModel({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.brand = '',
    this.colors = const [],
    this.category = '',
    this.imageUrls = const [],
    this.createdAt = '',
    this.timesWorn = 0,
    this.styleTags = const [],
    this.formality = '',
    this.season = '',
    this.pattern = '',
    this.material = '',
  });

  /// Première image (compatibilité avec l’ancien champ unique `image_url`).
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  // Propriété de compatibilité pour l'ancien format (une seule couleur)
  String get color => colors.isNotEmpty ? colors.first : '';

  factory GarmentModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    // Support de l'ancien format (color: String) et du nouveau (colors: List)
    List<String> colorsList = [];
    if (map['colors'] != null) {
      if (map['colors'] is List) {
        colorsList = List<String>.from(map['colors']);
      }
    } else if (map['color'] != null && map['color'].toString().isNotEmpty) {
      // Migration depuis l'ancien format
      colorsList = [map['color'].toString()];
    }

    List<String> urls = [];
    if (map['image_urls'] != null && map['image_urls'] is List) {
      urls = (map['image_urls'] as List)
          .map((e) => e.toString())
          .where((u) => u.isNotEmpty)
          .toList();
    }
    if (urls.isEmpty &&
        map['image_url'] != null &&
        map['image_url'].toString().isNotEmpty) {
      urls = [map['image_url'].toString()];
    }

    return GarmentModel(
      id: docId ?? map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      colors: colorsList,
      category: map['category'] ?? '',
      imageUrls: urls,
      createdAt: map['created_at'] ?? '',
      timesWorn: map['times_worn'] ?? 0,
      styleTags: List<String>.from(map['style_tags'] ?? const []),
      formality: map['formality'] ?? '',
      season: map['season'] ?? '',
      pattern: map['pattern'] ?? '',
      material: map['material'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'brand': brand,
        'colors': colors, // Nouveau format
        'color': colors.isNotEmpty ? colors.first : '', // Compatibilité
        'category': category,
        'image_urls': imageUrls,
        'image_url': imageUrl, // Compatibilité lecture ancienne doc
        'created_at': createdAt,
        'times_worn': timesWorn,
        'style_tags': styleTags,
        'formality': formality,
        'season': season,
        'pattern': pattern,
        'material': material,
      };

  GarmentModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? brand,
    List<String>? colors,
    String? category,
    List<String>? imageUrls,
    String? createdAt,
    int? timesWorn,
    List<String>? styleTags,
    String? formality,
    String? season,
    String? pattern,
    String? material,
  }) {
    return GarmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      colors: colors ?? this.colors,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      timesWorn: timesWorn ?? this.timesWorn,
      styleTags: styleTags ?? this.styleTags,
      formality: formality ?? this.formality,
      season: season ?? this.season,
      pattern: pattern ?? this.pattern,
      material: material ?? this.material,
    );
  }
}
