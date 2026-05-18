import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';

/// Notifier qui écoute les changements d'auth et de user pour déclencher
/// une réévaluation des redirects GoRouter - sans recréer le router.
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
    final isOnAuthPage = state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup';
    final isOnboarding = state.matchedLocation == '/onboarding';

    if (authLoading) return null;

    if (!isAuth && !isOnAuthPage) return '/login';

    if (isAuth && isOnAuthPage) {
      if (userLoading) return null;
      final user = currentUser.valueOrNull;
      if (user == null || user.isNewUser) return '/onboarding';
      return '/home';
    }

    if (isAuth && isOnboarding) {
      final user = currentUser.valueOrNull;
      if (user != null && !user.isNewUser) return '/home';
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
    ],
  );
});
