import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisaps/providers/auth_provider.dart';
import '../helpers/fakes.dart';

void main() {
  late FakeAuthService fakeAuth;
  late FakeFirestoreService fakeDb;
  late ProviderContainer container;

  setUp(() {
    fakeAuth = FakeAuthService();
    fakeDb = FakeFirestoreService();
    container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(fakeAuth),
      firestoreServiceProvider.overrideWithValue(fakeDb),
    ]);
  });

  tearDown(() => container.dispose());

  AuthNotifier n() => container.read(authNotifierProvider.notifier);

  // ── État initial ───────────────────────────────────────────────────────────

  test('état initial est AsyncData(null)', () {
    expect(container.read(authNotifierProvider).hasValue, true);
    expect(container.read(authNotifierProvider).hasError, false);
  });

  // ── signIn ─────────────────────────────────────────────────────────────────

  group('signIn', () {
    test('succès → retourne true', () async {
      fakeAuth.mockSuccess();
      final result = await n().signIn('test@test.com', 'password123');
      expect(result, true);
    });

    test('succès → état final est AsyncData(null)', () async {
      fakeAuth.mockSuccess();
      await n().signIn('test@test.com', 'password123');
      expect(container.read(authNotifierProvider).hasValue, true);
      expect(container.read(authNotifierProvider).hasError, false);
    });

    test('FirebaseAuthException → retourne false', () async {
      fakeAuth.mockFailure(
        FirebaseAuthException(code: 'wrong-password', message: 'Mot de passe incorrect'),
      );
      final result = await n().signIn('test@test.com', 'wrong');
      expect(result, false);
    });

    test('FirebaseAuthException → état est AsyncError', () async {
      fakeAuth.mockFailure(
        FirebaseAuthException(code: 'user-not-found', message: 'Utilisateur introuvable'),
      );
      await n().signIn('test@test.com', 'wrong');
      expect(container.read(authNotifierProvider).hasError, true);
    });

    test('FirebaseAuthException → message d\'erreur correct', () async {
      fakeAuth.mockFailure(
        FirebaseAuthException(code: 'test', message: 'Erreur custom'),
      );
      await n().signIn('test@test.com', 'wrong');
      final state = container.read(authNotifierProvider);
      expect(state.error.toString(), contains('Erreur custom'));
    });

    test('exception générique → retourne false', () async {
      fakeAuth.mockFailure(Exception('Erreur réseau'));
      final result = await n().signIn('test@test.com', 'pass');
      expect(result, false);
    });
  });

  // ── signUp ─────────────────────────────────────────────────────────────────

  group('signUp', () {
    test('succès → retourne true', () async {
      fakeAuth.mockSuccess();
      final result = await n().signUp('new@test.com', 'password123');
      expect(result, true);
    });

    test('succès → état final est AsyncData(null)', () async {
      fakeAuth.mockSuccess();
      await n().signUp('new@test.com', 'password123');
      expect(container.read(authNotifierProvider).hasValue, true);
    });

    test('email déjà utilisé → retourne false', () async {
      fakeAuth.mockFailure(
        FirebaseAuthException(code: 'email-already-in-use', message: 'Email déjà utilisé'),
      );
      final result = await n().signUp('existing@test.com', 'pass');
      expect(result, false);
    });

    test('erreur d\'inscription → état est AsyncError', () async {
      fakeAuth.mockFailure(
        FirebaseAuthException(code: 'weak-password', message: 'Mot de passe trop faible'),
      );
      await n().signUp('test@test.com', '123');
      expect(container.read(authNotifierProvider).hasError, true);
    });
  });

  // ── signOut ────────────────────────────────────────────────────────────────

  group('signOut', () {
    test('signOut → état reste AsyncData(null)', () async {
      await n().signOut();
      expect(container.read(authNotifierProvider).hasValue, true);
      expect(container.read(authNotifierProvider).hasError, false);
    });
  });

  // ── completeOnboarding ────────────────────────────────────────────────────

  group('completeOnboarding', () {
    test('ne plante pas si currentUser est null', () async {
      await expectLater(
        n().completeOnboarding(
          username: 'testuser',
          displayName: 'Test',
          profilePhotoUrl: '',
        ),
        completes,
      );
    });
  });
}
