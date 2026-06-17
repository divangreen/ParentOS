import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    ],
    redirect: (context, state) {
      // Still restoring a persisted session -- don't redirect yet, avoids a login flash.
      if (authState is AuthInitial) return null;

      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (authState is AuthAuthenticated && isAuthRoute) {
        return '/';
      }
      if (authState is! AuthAuthenticated && !isAuthRoute) {
        return '/login';
      }
      return null;
    },
  );
});
