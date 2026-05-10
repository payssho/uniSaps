import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Transforme une URL `storage.googleapis.com/...` en URL de téléchargement
/// signée (jeton) pour que [CachedNetworkImage] puisse charger l’image lorsque
/// le bucket n’est pas lisible publiquement.
Future<String> resolveFirebaseStorageDisplayUrl(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  // URL déjà au format Firebase avec jeton
  if (trimmed.contains('firebasestorage.googleapis.com') &&
      trimmed.contains('token=')) {
    return trimmed;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return trimmed;

  // Ancienne URL GCS « publique » sans jeton
  if (uri.host == 'storage.googleapis.com') {
    final segs = uri.pathSegments;
    if (segs.length < 2) return trimmed;

    final bucket = segs.first;
    final objectPath = segs.skip(1).join('/');

    try {
      final app = Firebase.app();
      final optsBucket =
          (Firebase.app().options.storageBucket ?? '').replaceFirst('gs://', '');
      Reference ref;
      if (optsBucket.isNotEmpty && bucket == optsBucket) {
        ref = FirebaseStorage.instance.ref(objectPath);
      } else {
        ref = FirebaseStorage.instanceFor(
          app: app,
          bucket: 'gs://$bucket',
        ).ref(objectPath);
      }
      return await ref.getDownloadURL();
    } catch (_) {
      return trimmed;
    }
  }

  return trimmed;
}
