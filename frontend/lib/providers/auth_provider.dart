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

/// Abonnement UniSaps+ (champ Firestore `account_tier` = `premium`).
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).valueOrNull?.isPremium ?? false;
});

final isCreatorAccountProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).valueOrNull?.isCreator ?? false;
});

final isCreatorSubscriptionActiveProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).valueOrNull?.isCreatorSubscriptionActive ??
      false;
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

  Future<void> completeCreatorOnboarding({
    required String username,
    required String displayName,
    required String creatorBio,
    required String creatorShopUrl,
    required String creatorLogoUrl,
    required String linkedUserUid,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;
    final now = DateTime.now().toIso8601String();
    final expires = DateTime.now()
        .add(const Duration(days: 30))
        .toIso8601String();
    final existing = await _firestoreService.getUser(user.uid);
    if (existing == null) {
      await _firestoreService.createUser(UserModel(
        uid: user.uid,
        email: user.email ?? '',
        username: username,
        displayName: displayName,
        createdAt: now,
        isNewUser: false,
        accountType: 'creator',
        creatorBio: creatorBio,
        creatorShopUrl: creatorShopUrl,
        creatorLogoUrl: creatorLogoUrl,
        linkedUserUid: linkedUserUid,
        creatorSubscriptionStatus: 'active',
        creatorSubscriptionExpiresAt: expires,
      ));
    } else {
      await _firestoreService.updateUser(user.uid, {
        'username': username,
        'display_name': displayName,
        'is_new_user': false,
        'account_type': 'creator',
        'creator_bio': creatorBio,
        'creator_shop_url': creatorShopUrl,
        'creator_logo_url': creatorLogoUrl,
        'linked_user_uid': linkedUserUid,
        'creator_subscription_status': 'active',
        'creator_subscription_expires_at': expires,
      });
    }
  }

  Future<void> activateCreatorSubscriptionStub() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final expires = DateTime.now()
        .add(const Duration(days: 30))
        .toIso8601String();
    final patch = {
      'account_type': 'creator',
      'creator_subscription_status': 'active',
      'creator_subscription_expires_at': expires,
    };
    final existing = await _firestoreService.getUser(user.uid);
    if (existing == null) {
      await _firestoreService.createUser(UserModel(
        uid: user.uid,
        email: user.email ?? '',
        createdAt: DateTime.now().toIso8601String(),
        isNewUser: true,
        accountType: 'creator',
        creatorSubscriptionStatus: 'active',
        creatorSubscriptionExpiresAt: expires,
      ));
    } else {
      await _firestoreService.updateUser(user.uid, patch);
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

  /// Supprime les données Firestore puis le compte Firebase Auth.
  /// Lance une exception si le mot de passe est incorrect.
  Future<void> deleteAccount({required String uid, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.deleteUserData(uid);
      await _authService.deleteAccount(password);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      rethrow;
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(firestoreServiceProvider),
  );
});
