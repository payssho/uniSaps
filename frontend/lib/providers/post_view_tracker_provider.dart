import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_explore_feed_posts.dart';
import 'auth_provider.dart';

/// Enregistre une vue par post et par session (évite les doublons).
class PostViewTracker {
  PostViewTracker(this._ref);

  final Ref _ref;
  final Set<String> _counted = {};

  Future<void> registerView(String postId) async {
    if (postId.isEmpty || isDevMockExplorePostId(postId)) return;
    if (_counted.contains(postId)) return;
    _counted.add(postId);
    try {
      await _ref.read(firestoreServiceProvider).incrementPostView(postId);
    } catch (_) {
      _counted.remove(postId);
    }
  }
}

final postViewTrackerProvider = Provider<PostViewTracker>((ref) {
  return PostViewTracker(ref);
});
