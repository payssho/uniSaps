class GarmentModel {
  final String id;
  final String userId;
  final String name;
  final String brand;
  final String color;
  final String category;
  final String imageUrl;
  final String createdAt;
  final int timesWorn;

  const GarmentModel({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.brand = '',
    this.color = '',
    this.category = '',
    this.imageUrl = '',
    this.createdAt = '',
    this.timesWorn = 0,
  });

  factory GarmentModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return GarmentModel(
      id: docId ?? map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      color: map['color'] ?? '',
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
        'color': color,
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
    String? color,
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
      color: color ?? this.color,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      timesWorn: timesWorn ?? this.timesWorn,
    );
  }
}
