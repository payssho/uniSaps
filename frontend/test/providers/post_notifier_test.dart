import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/providers/auth_provider.dart';
import 'package:unisaps/providers/garment_provider.dart';
import 'package:unisaps/providers/post_provider.dart';
import '../helpers/fakes.dart';

void main() {
  late FakeFirestoreService fakeDb;
  late FakeStorageService fakeStorage;
  late ProviderContainer container;

  setUp(() {
    fakeDb = FakeFirestoreService();
    fakeStorage = FakeStorageService();
    container = ProviderContainer(overrides: [
      firestoreServiceProvider.overrideWithValue(fakeDb),
      storageServiceProvider.overrideWithValue(fakeStorage),
    ]);
  });

  tearDown(() => container.dispose());

  PostNotifier n() => container.read(postNotifierProvider.notifier);

  final fakeBytes = Uint8List.fromList([0, 1, 2, 3, 4]);

  // ── createPost ─────────────────────────────────────────────────────────────

  group('createPost', () {
    test('succès → retourne true', () async {
      fakeStorage.uploadResult = 'https://cdn.url/post.jpg';
      final ok = await n().createPost(
        userId: 'uid-1',
        username: 'testuser',
        userPhotoUrl: 'https://photo.url',
        imageBytes: fakeBytes,
        imageName: 'post.jpg',
        caption: 'Mon look',
      );
      expect(ok, true);
    });

    test('succès → post ajouté dans le fake DB', () async {
      await n().createPost(
        userId: 'uid-1',
        username: 'testuser',
        userPhotoUrl: '',
        imageBytes: fakeBytes,
        imageName: 'post.jpg',
        caption: 'Look du jour',
      );
      expect(fakeDb.posts, isNotEmpty);
      expect(fakeDb.posts.first.caption, 'Look du jour');
      expect(fakeDb.posts.first.userId, 'uid-1');
    });

    test('succès → imageUrl est celle retournée par Storage', () async {
      fakeStorage.uploadResult = 'https://cdn.url/my-post.jpg';
      await n().createPost(
        userId: 'uid-1',
        username: 'testuser',
        userPhotoUrl: '',
        imageBytes: fakeBytes,
        imageName: 'post.jpg',
      );
      expect(fakeDb.posts.first.imageUrl, 'https://cdn.url/my-post.jpg');
    });

    test('succès → état final est AsyncData(null)', () async {
      await n().createPost(
        userId: 'uid-1',
        username: 'testuser',
        userPhotoUrl: '',
        imageBytes: fakeBytes,
        imageName: 'post.jpg',
      );
      expect(container.read(postNotifierProvider).hasValue, true);
    });

    test('erreur Storage → retourne false et état AsyncError', () async {
      fakeStorage.nextError = Exception('Storage error');
      final ok = await n().createPost(
        userId: 'uid-1',
        username: 'testuser',
        userPhotoUrl: '',
        imageBytes: fakeBytes,
        imageName: 'post.jpg',
      );
      expect(ok, false);
      expect(container.read(postNotifierProvider).hasError, true);
    });
  });

  // ── createPostFromDaily ────────────────────────────────────────────────────

  group('createPostFromDaily', () {
    test('succès avec dailyPhotoUrl → retourne true', () async {
      final user =
          fakeUser(uid: 'uid-1').copyWith(dailyPhotoUrl: 'https://daily.url/photo.jpg');
      final ok = await n().createPostFromDaily(
        user: user,
        outfit: fakeOutfit(),
        garments: [fakeGarment()],
        caption: 'Look du jour',
      );
      expect(ok, true);
    });

    test('dailyPhotoUrl vide → retourne false', () async {
      final user = fakeUser(uid: 'uid-1'); // dailyPhotoUrl vide
      final ok = await n().createPostFromDaily(
        user: user,
        outfit: fakeOutfit(),
        garments: [],
      );
      expect(ok, false);
    });

    test('succès → post contient les garmentRefs', () async {
      final user =
          fakeUser(uid: 'uid-1').copyWith(dailyPhotoUrl: 'https://daily.url/photo.jpg');
      await n().createPostFromDaily(
        user: user,
        outfit: fakeOutfit(),
        garments: [
          fakeGarment(id: 'g-1', name: 'T-Shirt'),
          fakeGarment(id: 'g-2', name: 'Jean'),
        ],
        caption: 'Style',
      );
      expect(fakeDb.posts.first.garmentRefs, hasLength(2));
      expect(
          fakeDb.posts.first.garmentRefs.map((r) => r.name).toList(),
          contains('T-Shirt'));
    });

    test('succès → imageUrl est daily_photo_url de l\'user', () async {
      final user =
          fakeUser(uid: 'uid-1').copyWith(dailyPhotoUrl: 'https://daily-specific.url');
      await n().createPostFromDaily(user: user, outfit: fakeOutfit(), garments: []);
      expect(fakeDb.posts.first.imageUrl, 'https://daily-specific.url');
    });
  });

  // ── toggleLike ─────────────────────────────────────────────────────────────

  group('toggleLike', () {
    setUp(() {
      fakeDb.posts.add(fakePost(id: 'post-1', userId: 'uid-author', likedBy: []));
    });

    test('liker un post → ajoute l\'uid à likedBy', () async {
      await n().toggleLike('post-1', 'uid-liker');
      expect(fakeDb.posts.first.likedBy, contains('uid-liker'));
    });

    test('liker un post → incrémente les likes', () async {
      final before = fakeDb.posts.first.likes;
      await n().toggleLike('post-1', 'uid-liker');
      expect(fakeDb.posts.first.likes, before + 1);
    });

    test('déliker un post → retire l\'uid de likedBy', () async {
      fakeDb.posts.clear();
      fakeDb.posts.add(fakePost(id: 'post-1', likedBy: ['uid-liker']));
      await n().toggleLike('post-1', 'uid-liker');
      expect(fakeDb.posts.first.likedBy, isNot(contains('uid-liker')));
    });

    test('déliker → décrémente les likes', () async {
      fakeDb.posts.clear();
      fakeDb.posts.add(fakePost(id: 'post-1', likedBy: ['uid-liker']));
      final before = fakeDb.posts.first.likes;
      await n().toggleLike('post-1', 'uid-liker');
      expect(fakeDb.posts.first.likes, before - 1);
    });
  });

  // ── deletePost ─────────────────────────────────────────────────────────────

  group('deletePost', () {
    setUp(() {
      fakeDb.posts.addAll([fakePost(id: 'post-1'), fakePost(id: 'post-2')]);
    });

    test('supprime le post ciblé', () async {
      await n().deletePost('post-1');
      expect(fakeDb.posts.any((p) => p.id == 'post-1'), false);
    });

    test('ne supprime que le post ciblé', () async {
      await n().deletePost('post-1');
      expect(fakeDb.posts.any((p) => p.id == 'post-2'), true);
    });
  });
}
