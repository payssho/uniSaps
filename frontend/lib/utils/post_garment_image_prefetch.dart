import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/garment_model.dart';
import '../models/outfit_model.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import '../services/firebase_storage_display_url.dart';

/// Précharge les vignettes pièces (résolution Storage + cache image).
Future<void> prefetchGarmentRefImageUrls(
  BuildContext context,
  Iterable<String> rawUrls,
) async {
  for (final raw in rawUrls) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    try {
      final resolved = await resolveFirebaseStorageDisplayUrl(trimmed);
      if (!context.mounted) return;
      await precacheImage(
        CachedNetworkImageProvider(resolved),
        context,
        onError: (_, __) {},
      );
    } catch (_) {}
  }
}

/// Précharge les photos des pièces sous les posts d’un profil (dressing déjà en mémoire).
Future<void> prefetchProfilePostGarmentImages({
  required BuildContext context,
  required List<PostModel> posts,
  required List<GarmentModel> ownerGarments,
  List<OutfitModel> ownerOutfits = const [],
}) async {
  final urls = <String>{};
  for (final post in posts) {
    final garments = garmentsForPostEnrichment(
      post,
      ownerGarments,
      ownerOutfits: ownerOutfits,
    );
    final refs = enrichGarmentRefs(post: post, garments: garments);
    for (final r in refs) {
      if (r.imageUrl.isNotEmpty) urls.add(r.imageUrl);
    }
  }
  await prefetchGarmentRefImageUrls(context, urls);
}
