class OutfitModel {
  final String id;
  final String userId;
  final String name;
  final Map<String, String> garments;
  final String createdAt;
  final int timesWorn;
  final String lastWorn;
  final List<String> wearHistory;
  final List<String> photoUrls;

  const OutfitModel({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.garments = const {},
    this.createdAt = '',
    this.timesWorn = 0,
    this.lastWorn = '',
    this.wearHistory = const [],
    this.photoUrls = const [],
  });

  static const defaultGarments = {
    'headwear': '',
    'top': '',
    'outerwear': '',
    'bottom': '',
    'shoes': '',
    'accessory': '',
  };

  factory OutfitModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawGarments = map['garments'];
    final garments = <String, String>{};
    if (rawGarments is Map) {
      for (final e in rawGarments.entries) {
        garments[e.key.toString()] = e.value?.toString() ?? '';
      }
    }
    return OutfitModel(
      id: docId ?? map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      garments: garments,
      createdAt: map['created_at'] ?? '',
      timesWorn: map['times_worn'] ?? 0,
      lastWorn: map['last_worn'] ?? '',
      wearHistory: List<String>.from(map['wear_history'] ?? []),
      photoUrls: List<String>.from(map['photo_urls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'garments': garments,
        'created_at': createdAt,
        'times_worn': timesWorn,
        'last_worn': lastWorn,
        'wear_history': wearHistory,
        'photo_urls': photoUrls,
      };

  List<String> get garmentIds =>
      garments.values.where((v) => v.isNotEmpty).toList();

  OutfitModel copyWith({
    String? id,
    String? userId,
    String? name,
    Map<String, String>? garments,
    String? createdAt,
    int? timesWorn,
    String? lastWorn,
    List<String>? wearHistory,
    List<String>? photoUrls,
  }) {
    return OutfitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      garments: garments ?? this.garments,
      createdAt: createdAt ?? this.createdAt,
      timesWorn: timesWorn ?? this.timesWorn,
      lastWorn: lastWorn ?? this.lastWorn,
      wearHistory: wearHistory ?? this.wearHistory,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }
}
