class GarmentRef {
  final String name;
  final String brand;
  final String imageUrl;

  const GarmentRef({this.name = '', this.brand = '', this.imageUrl = ''});

  factory GarmentRef.fromMap(Map<String, dynamic> map) {
    return GarmentRef(
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      imageUrl: map['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'brand': brand,
        'image_url': imageUrl,
      };
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
  final int viewCount;
  final List<String> likedBy;
  final String createdAt;
  /// Dénormalisé : statut premium de l’auteur au moment du post.
  final bool authorIsPremium;
  final String postKind;
  final bool isSponsored;
  final bool isActive;
  final String collectionId;
  final String previewImageUrl;

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
    this.viewCount = 0,
    this.likedBy = const [],
    this.createdAt = '',
    this.authorIsPremium = false,
    this.postKind = 'organic',
    this.isSponsored = false,
    this.isActive = true,
    this.collectionId = '',
    this.previewImageUrl = '',
  });

  bool get isOrganic => postKind != 'sponsored' && !isSponsored;

  String get displayImageUrl =>
      previewImageUrl.isNotEmpty ? previewImageUrl : imageUrl;

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
      viewCount: (map['view_count'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(map['liked_by'] ?? []),
      createdAt: map['created_at'] ?? '',
      authorIsPremium: map['author_is_premium'] == true,
      postKind: map['post_kind'] as String? ?? 'organic',
      isSponsored: map['is_sponsored'] == true,
      isActive: map['is_active'] != false,
      collectionId: map['collection_id'] ?? '',
      previewImageUrl: map['preview_image_url'] ?? '',
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
        'view_count': viewCount,
        'liked_by': likedBy,
        'created_at': createdAt,
        'author_is_premium': authorIsPremium,
        'post_kind': postKind,
        'is_sponsored': isSponsored,
        'is_active': isActive,
        'collection_id': collectionId,
        'preview_image_url': previewImageUrl,
      };

  bool isLikedBy(String uid) => likedBy.contains(uid);

  PostModel copyWith({
    String? id,
    bool? isActive,
    String? caption,
    String? previewImageUrl,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId,
      username: username,
      userPhotoUrl: userPhotoUrl,
      imageUrl: imageUrl,
      outfitId: outfitId,
      garmentRefs: garmentRefs,
      caption: caption ?? this.caption,
      likes: likes,
      likedBy: likedBy,
      createdAt: createdAt,
      authorIsPremium: authorIsPremium,
      postKind: postKind,
      isSponsored: isSponsored,
      isActive: isActive ?? this.isActive,
      collectionId: collectionId,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
    );
  }
}
