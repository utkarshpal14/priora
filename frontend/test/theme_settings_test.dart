import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_controller.dart';
import 'package:frontend/features/attachments/data/attachments_repository.dart';
import 'package:frontend/features/auth/domain/auth_state.dart';
import 'package:frontend/features/auth/domain/user_model.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/goals/data/goals_repository.dart';
import 'package:frontend/features/reminders/data/reminders_repository.dart';
import 'package:frontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:frontend/features/tasks/data/tasks_repository.dart';
import 'package:frontend/shared/widgets/app_empty_view.dart';
import 'package:frontend/shared/widgets/app_error_view.dart';

import 'tasks_test.dart';

class FakeAuthController extends StateNotifier<AuthState> implements AuthController {
  FakeAuthController()
      : super(
          const AuthState(
            status: AuthStatus.authenticated,
            user: UserModel(
              id: 'user-1',
              email: 'test@priora.app',
              fullName: 'Utkarsh Pal',
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme & AppAccentColor Tests', () {
    test('AppAccentColor.fromString returns correct enum', () {
      expect(AppAccentColor.fromString('indigo'), AppAccentColor.indigo);
      expect(AppAccentColor.fromString('BLUE'), AppAccentColor.blue);
      expect(AppAccentColor.fromString('green'), AppAccentColor.green);
      expect(AppAccentColor.fromString('orange'), AppAccentColor.orange);
      expect(AppAccentColor.fromString('purple'), AppAccentColor.purple);
      expect(AppAccentColor.fromString('invalid'), AppAccentColor.indigo);
    });

    testWidgets('AppTheme generates lightTheme and darkTheme with dynamic accent color', (tester) async {
      final light = AppTheme.lightTheme(AppAccentColor.green);
      expect(light.brightness, Brightness.light);
      expect(light.colorScheme.secondary, AppAccentColor.green.lightColor);

      final dark = AppTheme.darkTheme(AppAccentColor.purple);
      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme.secondary, AppAccentColor.purple.darkColor);
    });
  });

  group('ThemeController Tests', () {
    test('ThemeController defaults to system mode, indigo accent, and reduceMotion false', () {
      final controller = ThemeController();
      expect(controller.debugState.mode, ThemeMode.system);
      expect(controller.debugState.accent, AppAccentColor.indigo);
      expect(controller.debugState.reduceMotion, false);
    });

    test('ThemeController updates mode, accent color, and reduce motion state', () async {
      final container = ProviderContainer();
      final controller = container.read(themeControllerProvider.notifier);

      await controller.setThemeMode(ThemeMode.dark);
      expect(container.read(themeControllerProvider).mode, ThemeMode.dark);

      await controller.setAccentColor(AppAccentColor.orange);
      expect(container.read(themeControllerProvider).accent, AppAccentColor.orange);

      await controller.setReduceMotion(true);
      expect(container.read(themeControllerProvider).reduceMotion, true);

      container.dispose();
    });
  });

  group('Reusable Shared Widgets Tests', () {
    testWidgets('AppEmptyView renders title, message, and optional action button', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyView(
              icon: Icons.task_alt_rounded,
              title: 'No tasks yet',
              message: 'Create your first task to get started.',
              actionLabel: 'Add Task',
              onActionPressed: () {
                actionTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.text('Create your first task to get started.'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);

      await tester.tap(find.text('Add Task'));
      expect(actionTapped, true);
    });

    testWidgets('AppErrorView renders title, error message, and retry button', (tester) async {
      bool retryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              message: 'Failed to connect to backend server.',
              onRetry: () {
                retryTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Unable to Load Data'), findsOneWidget);
      expect(find.text('Failed to connect to backend server.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryTapped, true);
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('SettingsScreen renders Theme Mode, Accent Palette, and App Version cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tasksRepositoryProvider.overrideWithValue(FakeTasksRepository()),
            goalsRepositoryProvider.overrideWithValue(FakeGoalsRepository()),
            remindersRepositoryProvider.overrideWithValue(FakeRemindersRepository()),
            attachmentsRepositoryProvider.overrideWithValue(FakeAttachmentsRepository()),
            authControllerProvider.overrideWith((ref) => FakeAuthController()),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings & Preferences'), findsOneWidget);
      expect(find.text('Appearance & Theme'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Accent Color Palette'), findsOneWidget);
      expect(find.text('Accessibility & Motion'), findsOneWidget);
      expect(find.text('Reduce Motion'), findsOneWidget);
      expect(find.text('Data & Storage Usage'), findsOneWidget);
      expect(find.text('v1.0.0 (Build 100)'), findsOneWidget);
      expect(find.text('Coming in M11'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });
  });
}
