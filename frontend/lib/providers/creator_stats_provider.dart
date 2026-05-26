import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import 'auth_provider.dart';
import 'creator_post_provider.dart';

class CreatorStats {
  final int totalPosts;
  final int activePosts;
  final int inactivePosts;
  final int totalViews;
  final int totalLikes;

  const CreatorStats({
    this.totalPosts = 0,
    this.activePosts = 0,
    this.inactivePosts = 0,
    this.totalViews = 0,
    this.totalLikes = 0,
  });

  List<PostModel> topPostsByViews(List<PostModel> posts, {int limit = 3}) {
    final sorted = List<PostModel>.from(posts)
      ..sort((a, b) {
        final v = b.viewCount.compareTo(a.viewCount);
        if (v != 0) return v;
        return b.likes.compareTo(a.likes);
      });
    return sorted.take(limit).toList();
  }
}

final creatorStatsProvider = Provider<CreatorStats>((ref) {
  final uid = ref.watch(authServiceProvider).uid;
  if (uid.isEmpty) return const CreatorStats();
  final posts = ref.watch(creatorPostsProvider(uid)).valueOrNull ?? [];
  var views = 0;
  var likes = 0;
  var active = 0;
  for (final p in posts) {
    views += p.viewCount;
    likes += p.likes;
    if (p.isActive) {
      active++;
    }
  }
  return CreatorStats(
    totalPosts: posts.length,
    activePosts: active,
    inactivePosts: posts.length - active,
    totalViews: views,
    totalLikes: likes,
  );
});
