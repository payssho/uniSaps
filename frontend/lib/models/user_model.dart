import 'style_profile.dart';

class TutorialState {
  final bool dressing;
  final bool creations;
  final bool outfits;
  final bool profile;
  final bool inspiration;

  const TutorialState({
    this.dressing = false,
    this.creations = false,
    this.outfits = false,
    this.profile = false,
    this.inspiration = false,
  });

  factory TutorialState.fromMap(Map<String, dynamic> map) {
    return TutorialState(
      dressing: map['dressing'] ?? false,
      creations: map['creations'] ?? false,
      outfits: map['outfits'] ?? false,
      profile: map['profile'] ?? false,
      inspiration: map['inspiration'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'dressing': dressing,
        'creations': creations,
        'outfits': outfits,
        'profile': profile,
        'inspiration': inspiration,
      };

  TutorialState copyWith({
    bool? dressing,
    bool? creations,
    bool? outfits,
    bool? profile,
    bool? inspiration,
  }) {
    return TutorialState(
      dressing: dressing ?? this.dressing,
      creations: creations ?? this.creations,
      outfits: outfits ?? this.outfits,
      profile: profile ?? this.profile,
      inspiration: inspiration ?? this.inspiration,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String profilePhotoUrl;
  final String createdAt;
  final TutorialState tutorialSeen;
  final int currentStreak;
  final int bestStreak;
  final String dailyOutfitId;
  final String dailyOutfitDate;
  final String dailyPhotoUrl;
  final bool isNewUser;
  final bool isPrivate;
  final List<String> friends;
  /// `free` ou `premium` (Firestore: `account_tier`).
  final String accountTier;
  /// `user` (défaut) ou `creator` (marque).
  final String accountType;
  final String creatorBio;
  final String creatorShopUrl;
  final String creatorLogoUrl;
  final String linkedUserUid;
  final String creatorSubscriptionStatus;
  final String creatorSubscriptionExpiresAt;
  final StyleProfile? styleProfile;

  const UserModel({
    this.uid = '',
    this.email = '',
    this.username = '',
    this.displayName = '',
    this.profilePhotoUrl = '',
    this.createdAt = '',
    this.tutorialSeen = const TutorialState(),
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.dailyOutfitId = '',
    this.dailyOutfitDate = '',
    this.dailyPhotoUrl = '',
    this.isNewUser = true,
    this.isPrivate = false,
    this.friends = const [],
    this.accountTier = 'free',
    this.accountType = 'user',
    this.creatorBio = '',
    this.creatorShopUrl = '',
    this.creatorLogoUrl = '',
    this.linkedUserUid = '',
    this.creatorSubscriptionStatus = 'inactive',
    this.creatorSubscriptionExpiresAt = '',
    this.styleProfile,
  });

  bool get hasStyleProfile =>
      styleProfile != null && styleProfile!.updatedAt.isNotEmpty;

  bool get isPremium =>
      accountTier.toLowerCase() == 'premium' ||
      accountTier.toLowerCase() == 'paid';

  bool get isCreator => accountType == 'creator';

  bool get isCreatorSubscriptionActive {
    if (!isCreator) return false;
    if (creatorSubscriptionStatus != 'active') return false;
    if (creatorSubscriptionExpiresAt.isEmpty) return true;
    final exp = DateTime.tryParse(creatorSubscriptionExpiresAt);
    if (exp == null) return true;
    return exp.isAfter(DateTime.now());
  }

  /// Photo affichée : logo marque pour les créateurs, sinon photo profil.
  String get displayAvatarUrl =>
      isCreator && creatorLogoUrl.isNotEmpty ? creatorLogoUrl : profilePhotoUrl;

  bool isFriendWith(String uid) => friends.contains(uid);

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      displayName: map['display_name'] ?? '',
      profilePhotoUrl: map['profile_photo_url'] ?? '',
      createdAt: map['created_at'] ?? '',
      tutorialSeen: map['tutorial_seen'] != null
          ? TutorialState.fromMap(Map<String, dynamic>.from(map['tutorial_seen']))
          : const TutorialState(),
      currentStreak: map['current_streak'] ?? 0,
      bestStreak: map['best_streak'] ?? 0,
      dailyOutfitId: map['daily_outfit_id'] ?? '',
      dailyOutfitDate: map['daily_outfit_date'] ?? '',
      dailyPhotoUrl: map['daily_photo_url'] ?? '',
      isNewUser: map['is_new_user'] ?? true,
      isPrivate: map['is_private'] ?? false,
      friends: List<String>.from(map['friends'] ?? []),
      accountTier: map['account_tier'] as String? ?? 'free',
      accountType: map['account_type'] as String? ?? 'user',
      creatorBio: map['creator_bio'] ?? '',
      creatorShopUrl: map['creator_shop_url'] ?? '',
      creatorLogoUrl: map['creator_logo_url'] ?? '',
      linkedUserUid: map['linked_user_uid'] ?? '',
      creatorSubscriptionStatus:
          map['creator_subscription_status'] as String? ?? 'inactive',
      creatorSubscriptionExpiresAt:
          map['creator_subscription_expires_at'] ?? '',
      styleProfile: map['style_profile'] != null
          ? StyleProfile.fromMap(
              Map<String, dynamic>.from(map['style_profile'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'username': username,
        'display_name': displayName,
        'profile_photo_url': profilePhotoUrl,
        'created_at': createdAt,
        'tutorial_seen': tutorialSeen.toMap(),
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'daily_outfit_id': dailyOutfitId,
        'daily_outfit_date': dailyOutfitDate,
        'daily_photo_url': dailyPhotoUrl,
        'is_new_user': isNewUser,
        'is_private': isPrivate,
        'friends': friends,
        'account_tier': accountTier,
        'account_type': accountType,
        'creator_bio': creatorBio,
        'creator_shop_url': creatorShopUrl,
        'creator_logo_url': creatorLogoUrl,
        'linked_user_uid': linkedUserUid,
        'creator_subscription_status': creatorSubscriptionStatus,
        'creator_subscription_expires_at': creatorSubscriptionExpiresAt,
        if (styleProfile != null) 'style_profile': styleProfile!.toMap(),
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? profilePhotoUrl,
    String? createdAt,
    TutorialState? tutorialSeen,
    int? currentStreak,
    int? bestStreak,
    String? dailyOutfitId,
    String? dailyOutfitDate,
    String? dailyPhotoUrl,
    bool? isNewUser,
    bool? isPrivate,
    List<String>? friends,
    String? accountTier,
    String? accountType,
    String? creatorBio,
    String? creatorShopUrl,
    String? creatorLogoUrl,
    String? linkedUserUid,
    String? creatorSubscriptionStatus,
    String? creatorSubscriptionExpiresAt,
    StyleProfile? styleProfile,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      tutorialSeen: tutorialSeen ?? this.tutorialSeen,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      dailyOutfitId: dailyOutfitId ?? this.dailyOutfitId,
      dailyOutfitDate: dailyOutfitDate ?? this.dailyOutfitDate,
      dailyPhotoUrl: dailyPhotoUrl ?? this.dailyPhotoUrl,
      isNewUser: isNewUser ?? this.isNewUser,
      isPrivate: isPrivate ?? this.isPrivate,
      friends: friends ?? this.friends,
      accountTier: accountTier ?? this.accountTier,
      accountType: accountType ?? this.accountType,
      creatorBio: creatorBio ?? this.creatorBio,
      creatorShopUrl: creatorShopUrl ?? this.creatorShopUrl,
      creatorLogoUrl: creatorLogoUrl ?? this.creatorLogoUrl,
      linkedUserUid: linkedUserUid ?? this.linkedUserUid,
      creatorSubscriptionStatus:
          creatorSubscriptionStatus ?? this.creatorSubscriptionStatus,
      creatorSubscriptionExpiresAt:
          creatorSubscriptionExpiresAt ?? this.creatorSubscriptionExpiresAt,
      styleProfile: styleProfile ?? this.styleProfile,
    );
  }
}
