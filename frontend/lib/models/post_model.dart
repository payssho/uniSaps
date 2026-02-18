class GarmentRef {
  final String name;
  final String brand;

  const GarmentRef({this.name = '', this.brand = ''});

  factory GarmentRef.fromMap(Map<String, dynamic> map) {
    return GarmentRef(
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'brand': brand};
}

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String userPhotoUrl;
  final String imageUrl;
  final String outfitId;
  final List<GarmentRef> garmentRefs;
  final String caption;
  final int likes;
  final List<String> likedBy;
  final String createdAt;

  const PostModel({
    this.id = '',
    this.userId = '',
    this.username = '',
    this.userPhotoUrl = '',
    this.imageUrl = '',
    this.outfitId = '',
    this.garmentRefs = const [],
    this.caption = '',
    this.likes = 0,
    this.likedBy = const [],
    this.createdAt = '',
  });

  factory PostModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final refs = (map['garment_refs'] as List? ?? [])
        .map((r) => GarmentRef.fromMap(Map<String, dynamic>.from(r)))
        .toList();
    return PostModel(
      id: docId ?? map['id'] ?? '',
      userId: map['user_id'] ?? '',
      username: map['username'] ?? '',
      userPhotoUrl: map['user_photo_url'] ?? '',
      imageUrl: map['image_url'] ?? '',
      outfitId: map['outfit_id'] ?? '',
      garmentRefs: refs,
      caption: map['caption'] ?? '',
      likes: map['likes'] ?? 0,
      likedBy: List<String>.from(map['liked_by'] ?? []),
      createdAt: map['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'username': username,
        'user_photo_url': userPhotoUrl,
        'image_url': imageUrl,
        'outfit_id': outfitId,
        'garment_refs': garmentRefs.map((r) => r.toMap()).toList(),
        'caption': caption,
        'likes': likes,
        'liked_by': likedBy,
        'created_at': createdAt,
      };

  bool isLikedBy(String uid) => likedBy.contains(uid);
}
