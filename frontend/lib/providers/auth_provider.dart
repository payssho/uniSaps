import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).userStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthNotifier(this._authService, this._firestoreService)
      : super(const AsyncValue.data(null));

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signIn(email, password);
      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Erreur de connexion', StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signUp(email, password);
      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Erreur d\'inscription', StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  Future<void> completeOnboarding({
    required String username,
    required String displayName,
    required String profilePhotoUrl,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;
    final now = DateTime.now().toIso8601String();
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      username: username,
      displayName: displayName,
      profilePhotoUrl: profilePhotoUrl,
      createdAt: now,
      isNewUser: false,
    );
    await _firestoreService.createUser(userModel);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(firestoreServiceProvider),
  );
});
