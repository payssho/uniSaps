import '../core/constants/feed_mix_config.dart';
import '../models/post_model.dart';

/// Mélange posts organiques et sponsorisés actifs pour le feed Explorer.
List<PostModel> mixExploreFeed({
  required List<PostModel> organic,
  required List<PostModel> sponsoredActive,
  int organicInterval = kSponsoredOrganicInterval,
}) {
  final sortedOrganic = List<PostModel>.from(organic)
    ..sort((a, b) {
      final da = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
      final db = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
      return db.compareTo(da);
    });

  if (sponsoredActive.isEmpty) return sortedOrganic;

  final sortedSponsored = List<PostModel>.from(sponsoredActive)
    ..sort((a, b) {
      final da = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
      final db = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
      return db.compareTo(da);
    });

  final result = <PostModel>[];
  var sponsorIndex = 0;
  for (var i = 0; i < sortedOrganic.length; i++) {
    result.add(sortedOrganic[i]);
    if ((i + 1) % organicInterval == 0 && sponsorIndex < sortedSponsored.length) {
      result.add(sortedSponsored[sponsorIndex]);
      sponsorIndex++;
    }
  }
  while (sponsorIndex < sortedSponsored.length) {
    result.add(sortedSponsored[sponsorIndex]);
    sponsorIndex++;
  }
  return result;
}
