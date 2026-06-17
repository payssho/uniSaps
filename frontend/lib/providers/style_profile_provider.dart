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

  /// Sauvegarde le profil style et applique [is_private] selon [socialIntent].
  Future<void> saveWithSocialIntent(StyleProfile profile) async {
    final uid = _ref.read(authServiceProvider).uid;
    if (uid.isEmpty) return;

    final payload = <String, dynamic>{
      'style_profile': profile.toMap(),
    };
    switch (profile.socialIntent) {
      case 'private':
        payload['is_private'] = true;
        break;
      case 'friends':
        payload['is_private'] = false;
        break;
      default:
        break;
    }
    await _ref.read(firestoreServiceProvider).updateUser(uid, payload);
    _ref.invalidate(currentUserProvider);
  }
}
