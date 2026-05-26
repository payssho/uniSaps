import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Cache mémoire des URLs déjà résolues : on évite un aller-retour réseau
/// Firebase Storage à chaque rebuild d'image.
final Map<String, String> _resolvedCache = <String, String>{};

/// URLs dont la résolution a échoué (permissions, objet absent) — ne pas réessayer l'URL GCS brute (403).
final Set<String> _resolveFailed = <String>{};

/// Cache des résolutions en cours pour éviter les requêtes en double quand
/// plusieurs widgets demandent la même URL en même temps.
final Map<String, Future<String>> _inFlight = <String, Future<String>>{};

/// Lookup synchrone d'une URL déjà résolue. Renvoie [null] si jamais vue.
String? cachedDisplayUrl(String url) {
  final t = url.trim();
  if (t.isEmpty || _resolveFailed.contains(t)) return null;
  return _resolvedCache[t];
}

/// Transforme une URL Storage (GCS ou Firebase) en URL de téléchargement avec jeton.
Future<String> resolveFirebaseStorageDisplayUrl(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  if (_resolveFailed.contains(trimmed)) {
    throw StateError('storage_resolve_failed');
  }

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

  final needsSign = uri.host == 'storage.googleapis.com' ||
      (uri.host.contains('firebasestorage.googleapis.com') &&
          !trimmed.contains('token='));

  if (!needsSign) {
    _resolvedCache[trimmed] = trimmed;
    return trimmed;
  }

  final future = _signUrl(trimmed, uri);
  _inFlight[trimmed] = future;
  try {
    return await future;
  } finally {
    _inFlight.remove(trimmed);
  }
}

Future<String> _signUrl(String original, Uri uri) async {
  Reference? ref;

  try {
    if (uri.host == 'storage.googleapis.com') {
      final segs = uri.pathSegments;
      if (segs.length < 2) {
        throw StateError('invalid_gcs_path');
      }
      final bucket = segs.first;
      final objectPath = segs.skip(1).join('/');
      final app = Firebase.app();
      final optsBucket =
          (Firebase.app().options.storageBucket ?? '').replaceFirst('gs://', '');
      if (optsBucket.isNotEmpty && bucket == optsBucket) {
        ref = FirebaseStorage.instance.ref(objectPath);
      } else {
        ref = FirebaseStorage.instanceFor(
          app: app,
          bucket: 'gs://$bucket',
        ).ref(objectPath);
      }
    } else if (uri.host.contains('firebasestorage.googleapis.com')) {
      ref = FirebaseStorage.instance.refFromURL(original);
    }
  } catch (e) {
    debugPrint('Storage ref build failed ($original): $e');
    _resolveFailed.add(original);
    throw StateError('storage_resolve_failed');
  }

  if (ref == null) {
    _resolveFailed.add(original);
    throw StateError('storage_resolve_failed');
  }

  try {
    final signed = await ref.getDownloadURL();
    _resolvedCache[original] = signed;
    return signed;
  } catch (e) {
    debugPrint(
      'Storage getDownloadURL failed ($original). '
      'Déploie storage.rules si profil ami (403). Erreur: $e',
    );
    _resolveFailed.add(original);
    throw StateError('storage_resolve_failed');
  }
}
