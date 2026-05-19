import '../models/post_model.dart';

/// Préfixe des IDs de posts factices injectés dans Explorer (dev / test pubs).
bool isDevMockExplorePostId(String id) => id.startsWith('dev_mock_explore_');

const _captions = <String>[
  'Nouvelle capsule SS26 — code MOCK20',
  'Soldes créateurs · jusqu’à -40 % cette semaine',
  'Lookbook studio · pièces limitées',
  'Essayage virtuel disponible · lien en bio',
  'Drop sneakers demain 10 h · notifications ON',
  'Collab exclusive · stock limité',
  'Tenues de bureau · coupe premium',
  'Marque locale · livraison 48 h',
  'Archive revisitée · pièces numérotées',
  'Outlet — derniers stocks · ne rate pas',
  'Cashmere & laine · hiver douillet',
  'Streetwear technique · coupe oversized',
  'Robes de soirée · rendez-vous showroom',
  'Denim japonais · patine unique',
  'Accessoires artisanaux · fabriqué en EU',
];

const _garmentPool = <GarmentRef>[
  GarmentRef(name: 'Blazer lin', brand: 'Maison Mock'),
  GarmentRef(name: 'Jean brut', brand: 'Atelier Test'),
  GarmentRef(name: 'Sac cuir', brand: 'Label Dev'),
  GarmentRef(name: 'Baskets blanches', brand: 'Street Lab'),
  GarmentRef(name: 'Trench beige', brand: 'Slowwear QA'),
  GarmentRef(name: 'Robe midi', brand: 'Studio Fictif'),
];

/// ~30 posts factices de volume pour le mode dev (pas des pubs).
final List<PostModel> kMockExploreFeedPosts = List<PostModel>.generate(
  30,
  (i) {
    final n = i + 1;
    final brandIdx = i % 6;
    return PostModel(
      id: 'dev_mock_explore_${n.toString().padLeft(3, '0')}',
      userId: 'dev_mock_brand_${brandIdx + 1}',
      username: 'mockbrand${brandIdx + 1}',
      userPhotoUrl: 'https://i.pravatar.cc/128?img=${(i % 60) + 1}',
      imageUrl:
          'https://picsum.photos/seed/unisaps_mock_$n/720/1080',
      outfitId: '',
      garmentRefs: i % 3 == 0
          ? const []
          : [_garmentPool[i % _garmentPool.length]],
      caption: _captions[i % _captions.length],
      likes: 12 + i * 17 + (i % 7),
      likedBy: const [],
      createdAt: DateTime.now()
          .toUtc()
          .subtract(Duration(minutes: 20 + i * 45))
          .toIso8601String(),
      authorIsPremium: i.isOdd,
      postKind: 'organic',
      isSponsored: false,
      isActive: true,
      collectionId: '',
      previewImageUrl: '',
    );
  },
);
