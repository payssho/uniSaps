import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/garment_model.dart';
import '../models/outfit_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'post_card.dart';

/// Aperçu d’un post sponsorisé tel qu’affiché dans le feed Explorer.
class CreatorPostPreviewSheet extends StatelessWidget {
  final PostModel post;
  final String previewUid;
  final List<GarmentModel> ownerGarments;
  final List<OutfitModel> ownerOutfits;

  const CreatorPostPreviewSheet({
    super.key,
    required this.post,
    this.previewUid = 'preview',
    this.ownerGarments = const [],
    this.ownerOutfits = const [],
  });

  static Future<void> show(
    BuildContext context,
    PostModel post, {
    List<GarmentModel> ownerGarments = const [],
    List<OutfitModel> ownerOutfits = const [],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      builder: (_) => CreatorPostPreviewSheet(
        post: post,
        ownerGarments: ownerGarments,
        ownerOutfits: ownerOutfits,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Aperçu feed Inspo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: PostCard(
                  post: post,
                  currentUid: previewUid,
                  onLike: () {},
                  ownerGarments: ownerGarments,
                  ownerOutfits: ownerOutfits,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Construit un post factice pour la preview avant publication.
PostModel buildPreviewPost({
  required UserModel brand,
  required String imageUrl,
  required List<GarmentRef> refs,
  String caption = '',
}) {
  return PostModel(
    userId: brand.uid,
    username: brand.username.isNotEmpty ? brand.username : brand.displayName,
    userPhotoUrl: brand.creatorLogoUrl.isNotEmpty
        ? brand.creatorLogoUrl
        : brand.profilePhotoUrl,
    imageUrl: imageUrl,
    previewImageUrl: imageUrl,
    garmentRefs: refs,
    caption: caption,
    createdAt: DateTime.now().toUtc().toIso8601String(),
    postKind: 'sponsored',
    isSponsored: true,
    isActive: true,
  );
}
