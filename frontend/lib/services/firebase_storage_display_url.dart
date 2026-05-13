import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Cache mémoire des URLs déjà résolues : on évite un aller-retour réseau
/// Firebase Storage à chaque rebuild d'image.
final Map<String, String> _resolvedCache = <String, String>{};

/// Cache des résolutions en cours pour éviter les requêtes en double quand
/// plusieurs widgets demandent la même URL en même temps.
final Map<String, Future<String>> _inFlight = <String, Future<String>>{};

/// Lookup synchrone d'une URL déjà résolue. Renvoie [null] si jamais vue.
String? cachedDisplayUrl(String url) => _resolvedCache[url.trim()];

/// Transforme une URL `storage.googleapis.com/...` en URL de téléchargement
/// signée (jeton) pour [CachedNetworkImage]. Mémorise le résultat pour qu'un
/// second appel sur la même URL soit instantané.
Future<String> resolveFirebaseStorageDisplayUrl(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  final cached = _resolvedCache[trimmed];
  if (cached != null) return cached;

  final inflight = _inFlight[trimmed];
  if (inflight != null) return inflight;

  if (trimmed.contains('firebasestorage.googleapis.com') &&
      trimmed.contains('token=')) {
    _resolvedCache[trimmed] = trimmed;
    return trimmed;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    _resolvedCache[trimmed] = trimmed;
    return trimmed;
  }

  if (uri.host != 'storage.googleapis.com') {
    _resolvedCache[trimmed] = trimmed;
    return trimmed;
  }

  final future = _signUrl(trimmed, uri);
  _inFlight[trimmed] = future;
  try {
    final signed = await future;
    return signed;
  } finally {
    _inFlight.remove(trimmed);
  }
}

Future<String> _signUrl(String original, Uri uri) async {
  try {
    final segs = uri.pathSegments;
    if (segs.length < 2) return original;
    final bucket = segs.first;
    final objectPath = segs.skip(1).join('/');
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
    final signed = await ref.getDownloadURL();
    _resolvedCache[original] = signed;
    return signed;
  } catch (_) {
    // En cas d'échec on garde l'URL d'origine (le bucket pourrait être public).
    _resolvedCache[original] = original;
    return original;
  }
}
