import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'config/theme.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/tourist/tourist_shell.dart';
import 'screens/ranger/ranger_shell.dart';

void main() {
  runApp(const ProviderScope(child: ForestGuardApp()));
}

class ForestGuardApp extends ConsumerWidget {
  const ForestGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ForestGuard',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: _router(ref),
    );
  }

  GoRouter _router(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectionScreen()),
        GoRoute(
          path: '/login',
          builder: (_, state) => LoginScreen(role: state.uri.queryParameters['role'] ?? 'tourist'),
        ),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        ShellRoute(
          builder: (_, __, child) => child,
          routes: [
            GoRoute(path: '/tourist', builder: (_, __) => const TouristShell()),
          ],
        ),
        ShellRoute(
          builder: (_, __, child) => child,
          routes: [
            GoRoute(path: '/ranger', builder: (_, __) => const RangerShell()),
          ],
        ),
      ],
    );
  }
}
