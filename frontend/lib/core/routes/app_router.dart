import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/creator/creator_landing_screen.dart';
import '../../screens/creator/creator_checkout_screen.dart';
import '../../screens/creator/creator_onboarding_screen.dart';
import '../../screens/creator/creator_home_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final currentUser = _ref.read(currentUserProvider);

    final isAuth = authState.valueOrNull != null;
    final authLoading = authState.isLoading;
    final userLoading = currentUser.isLoading;
    final loc = state.matchedLocation;

    final isOnAuthPage =
        loc == '/login' || loc == '/signup' || loc.startsWith('/creator');
    final isOnboarding = loc == '/onboarding';
    final isCreatorOnboarding = loc == '/creator/onboarding';
    final isCreatorCheckout = loc == '/creator/checkout';

    if (authLoading) return null;

    if (!isAuth) {
      if (loc.startsWith('/creator') && loc != '/creator') {
        return null;
      }
      if (!isOnAuthPage && loc != '/creator') return '/login';
      return null;
    }

    if (userLoading) return null;

    final user = currentUser.valueOrNull;

    if (user?.isCreator == true) {
      final u = user!;
      if (!u.isCreatorSubscriptionActive &&
          !isCreatorCheckout &&
          loc != '/creator') {
        return '/creator/checkout';
      }
      // Nouveau créateur : forcer l’onboarding marque, mais rester sur cette route
      // (évite la boucle onboarding ↔ home car `isOnAuthPage` inclut tout `/creator/*`).
      if (u.isNewUser) {
        if (!isCreatorOnboarding) {
          return '/creator/onboarding';
        }
        return null;
      }
      if (loc == '/creator/onboarding') {
        return '/creator/home';
      }
      if (loc == '/login' ||
          loc == '/signup' ||
          isOnboarding ||
          loc == '/home' ||
          loc == '/creator' ||
          loc == '/creator/checkout') {
        return '/creator/home';
      }
      return null;
    }

    if (isAuth && (loc == '/login' || loc == '/signup')) {
      if (user == null || user.isNewUser) return '/onboarding';
      return '/home';
    }

    if (isAuth && isOnboarding) {
      if (user != null && !user.isNewUser) return '/home';
    }

    if (isAuth && loc.startsWith('/creator/home')) {
      return '/home';
    }

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/creator',
        builder: (_, __) => const CreatorLandingScreen(),
      ),
      GoRoute(
        path: '/creator/checkout',
        builder: (_, __) => const CreatorCheckoutScreen(),
      ),
      GoRoute(
        path: '/creator/onboarding',
        builder: (_, __) => const CreatorOnboardingScreen(),
      ),
      GoRoute(
        path: '/creator/home',
        builder: (_, __) => const CreatorHomeScreen(),
      ),
    ],
  );
});
