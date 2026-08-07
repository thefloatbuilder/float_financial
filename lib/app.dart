import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/main/main_navigation_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/portfolio/portfolio_screen.dart';
import 'features/alerts/alerts_screen.dart';
import 'features/profile/profile_screen.dart';
import 'shared/providers/theme_provider.dart';

bool get _hasSupabaseSession {
  if (AppConfig.isDemoMode) return false;
  try {
    return Supabase.instance.client.auth.currentUser != null;
  } catch (_) {
    return false;
  }
}

/// Bridges Supabase auth state changes into GoRouter's refresh mechanism so
/// route guards re-evaluate the moment a user signs in or out — without this,
/// the redirect only runs on explicit navigation and sign-out can leave the
/// user stranded on an authed screen (and vice versa).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    if (!AppConfig.isDemoMode) {
      try {
        _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
          notifyListeners();
        });
      } catch (_) {
        // Supabase not initialized — nothing to listen to.
      }
    }
  }

  StreamSubscription<dynamic>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// Direct debug routes for each tab screen (prefixed /debug/...) exist because
// browser automation can't tap the in-app bottom nav bar (it's rendered on a
// Flutter web canvas, not real DOM elements). They are compiled out of
// release builds below via kReleaseMode — production only exposes real routes.
final _authRefresh = _AuthRefreshNotifier();

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  refreshListenable: _authRefresh,
  redirect: (context, state) {
    final path = state.uri.path;
    final isSplash = path == '/splash';
    final isGoingToLogin = path == '/';
    final isOnboarding = path == '/onboarding';

    if (isSplash) return null;

    // Demo mode: no real auth backend, keep every route reachable for review.
    if (AppConfig.isDemoMode) return null;

    // Production: unauthenticated users always land on login; authenticated
    // users hitting login go straight home (refreshListenable re-runs this
    // on every auth state change, so sign-in/out can't strand anyone).
    if (!_hasSupabaseSession && !isGoingToLogin && !isOnboarding) {
      return '/';
    }
    if (_hasSupabaseSession && isGoingToLogin) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const MainNavigationScreen()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
    // Debug-only direct routes — excluded from release builds.
    if (!const bool.fromEnvironment('dart.vm.product')) ...[
      GoRoute(path: '/debug/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/debug/portfolio', builder: (context, state) => const PortfolioScreen()),
      GoRoute(path: '/debug/alerts', builder: (context, state) => const AlertsScreen()),
      GoRoute(path: '/debug/profile', builder: (context, state) => const ProfileScreen()),
    ],
  ],
);

class FloatFinancialApp extends ConsumerWidget {
  const FloatFinancialApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Float Financial',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
