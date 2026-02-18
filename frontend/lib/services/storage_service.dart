import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadImageBytes(Uint8List bytes, String folder, String userId, String originalName) async {
    final ext = originalName.split('.').last.toLowerCase();
    final filename = '${_uuid.v4()}.$ext';
    final ref = _storage.ref('$folder/$userId/$filename');
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  Future<String> uploadGarmentImageBytes(Uint8List bytes, String userId, String originalName) =>
      uploadImageBytes(bytes, 'garments', userId, originalName);

  Future<String> uploadOutfitPhotoBytes(Uint8List bytes, String userId, String originalName) =>
      uploadImageBytes(bytes, 'outfits', userId, originalName);

  Future<String> uploadProfilePhotoBytes(Uint8List bytes, String userId, String originalName) =>
      uploadImageBytes(bytes, 'profiles', userId, originalName);

  Future<String> uploadPostImageBytes(Uint8List bytes, String userId, String originalName) =>
      uploadImageBytes(bytes, 'posts', userId, originalName);

  Future<void> deleteImage(String url) async {
    if (url.isEmpty) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
