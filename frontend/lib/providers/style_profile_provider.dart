import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/style_profile.dart';
import 'auth_provider.dart';

final styleProfileNotifierProvider =
    Provider<StyleProfileNotifier>((ref) => StyleProfileNotifier(ref));

class StyleProfileNotifier {
  StyleProfileNotifier(this._ref);

  final Ref _ref;

  Future<void> save(StyleProfile profile) async {
    final uid = _ref.read(authServiceProvider).uid;
    if (uid.isEmpty) return;
    await _ref.read(firestoreServiceProvider).updateUser(uid, {
      'style_profile': profile.toMap(),
    });
    _ref.invalidate(currentUserProvider);
  }
}
