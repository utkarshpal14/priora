import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/dashboard/presentation/screens/placeholder_screen.dart';
import '../features/goals/presentation/screens/goal_detail_screen.dart';
import '../features/goals/presentation/screens/goals_screen.dart';
import '../features/planner/presentation/screens/planner_screen.dart';
import '../features/review/presentation/screens/review_screen.dart';
import '../features/tasks/presentation/screens/tasks_screen.dart';
import '../shared/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
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
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/planner',
            name: 'planner',
            builder: (context, state) => const PlannerScreen(),
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
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticating = authState.status == AuthStatus.initial;
      if (isAuthenticating) {
        // App is still loading stored session on launch
        return null;
      }

      final isAuthenticated = authState.isAuthenticated;
      final location = state.uri.path;
      final isPublicRoute = location == '/login' || location == '/register';

      // 1. Unauthenticated users trying to access protected routes go to /login
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      // 2. Authenticated users on /login or /register go to /dashboard
      if (isAuthenticated && isPublicRoute) {
        return '/dashboard';
      }

      return null;
    },
  );
});
