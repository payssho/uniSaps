import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
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
    },
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
