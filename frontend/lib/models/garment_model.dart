class GarmentModel {
  final String id;
  final String userId;
  final String name;
  final String brand;
  final List<String> colors; // Support pour plusieurs couleurs
  final String category;
  final String imageUrl;
  final String createdAt;
  final int timesWorn;

  const GarmentModel({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.brand = '',
    this.colors = const [],
    this.category = '',
    this.imageUrl = '',
    this.createdAt = '',
    this.timesWorn = 0,
  });

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
    
    return GarmentModel(
      id: docId ?? map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      colors: colorsList,
      category: map['category'] ?? '',
      imageUrl: map['image_url'] ?? '',
      createdAt: map['created_at'] ?? '',
      timesWorn: map['times_worn'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'brand': brand,
        'colors': colors, // Nouveau format
        'color': colors.isNotEmpty ? colors.first : '', // Compatibilité
        'category': category,
        'image_url': imageUrl,
        'created_at': createdAt,
        'times_worn': timesWorn,
      };

  GarmentModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? brand,
    List<String>? colors,
    String? category,
    String? imageUrl,
    String? createdAt,
    int? timesWorn,
  }) {
    return GarmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      colors: colors ?? this.colors,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      timesWorn: timesWorn ?? this.timesWorn,
    );
  }
}
