import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/verify_email_screen.dart';
import '../features/dashboard/presentation/screens/placeholder_screen.dart';
import '../features/goals/presentation/screens/goal_detail_screen.dart';
import '../features/goals/presentation/screens/goals_screen.dart';
import '../features/planner/presentation/screens/planner_screen.dart';
import '../features/review/presentation/screens/review_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/tasks/presentation/screens/tasks_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../shared/widgets/main_scaffold.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);
    final location = state.uri.path;

    // Splash screen handles its own navigation when warmup finishes
    if (location == '/splash') {
      return null;
    }

    final isAuthenticating = authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.authenticating;
    if (isAuthenticating) {
      return null;
    }

    final isAuthenticated = authState.isAuthenticated;
    final isPublicRoute = location == '/login' || location == '/register' || location == '/verify-email';

    // 1. Unauthenticated users trying to access protected routes go to /login
    if (!isAuthenticated && !isPublicRoute) {
      return '/login';
    }

    // 2. Authenticated users on /login, /register, /verify-email, or / go to /planner
    if (isAuthenticated && (isPublicRoute || location == '/')) {
      return '/planner';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // Splash Route (UX-005 Cold-Start Warming)
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Public Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify_email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),

      // Goal Detail Screen
      GoRoute(
        path: '/goals/:id',
        name: 'goal_detail',
        builder: (context, state) => GoalDetailScreen(
          goalId: state.pathParameters['id']!,
        ),
      ),

      // Protected Shell Routes (with persistent bottom navigation)
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'root',
            builder: (context, state) => const PlannerScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const PlannerScreen(),
          ),
          GoRoute(
            path: '/planner',
            name: 'planner',
            builder: (context, state) => const PlannerScreen(),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/goals',
            name: 'goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/review',
            name: 'review',
            builder: (context, state) => const ReviewScreen(),
          ),
          GoRoute(
            path: '/reminders',
            name: 'reminders',
            builder: (context, state) => const PlaceholderScreen(),
          ),
          GoRoute(
            path: '/attachments',
            name: 'attachments',
            builder: (context, state) => const PlaceholderScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
