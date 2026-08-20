import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/attachments/data/attachments_repository.dart';
import 'package:frontend/features/auth/domain/auth_state.dart';
import 'package:frontend/features/auth/domain/user_model.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/goals/data/goals_repository.dart';
import 'package:frontend/features/reminders/data/reminders_repository.dart';
import 'package:frontend/features/settings/domain/notification_preferences_model.dart';
import 'package:frontend/features/settings/presentation/controllers/notification_settings_controller.dart';
import 'package:frontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:frontend/features/tasks/data/tasks_repository.dart';

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

  group('Milestone 11 — Notification Preferences Model & Controller Tests', () {
    test('NotificationPreferencesModel parses JSON and updates via copyWith', () {
      final json = {
        'notifications_enabled': true,
        'sound_enabled': false,
        'deadline_reminders': true,
        'session_reminders': true,
        'review_reminders': false,
        'goal_alerts': true,
      };

      final model = NotificationPreferencesModel.fromJson(json);
      expect(model.notificationsEnabled, true);
      expect(model.soundEnabled, false);
      expect(model.sessionReminders, true);
      expect(model.reviewReminders, false);

      final updated = model.copyWith(soundEnabled: true);
      expect(updated.soundEnabled, true);
      expect(updated.toJson()['sound_enabled'], true);
    });

    test('NotificationSettingsController toggles preferences properly', () async {
      final controller = NotificationSettingsController(null);

      await controller.toggleDeadlineReminders(false);
      expect(controller.debugState.deadlineReminders, false);

      await controller.toggleSessionReminders(false);
      expect(controller.debugState.sessionReminders, false);

      await controller.toggleReviewReminders(false);
      expect(controller.debugState.reviewReminders, false);

      await controller.toggleGoalAlerts(false);
      expect(controller.debugState.goalAlerts, false);
    });
  });

  group('Milestone 11 — SettingsScreen Live Notification Switches Widget Tests', () {
    testWidgets('SettingsScreen renders active Task Deadline, Evening Review, and Goal Alert switches', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
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
            notificationSettingsProvider.overrideWith((ref) => NotificationSettingsController(null)),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications & Alerts'), findsOneWidget);
      expect(find.text('Task Deadline Reminders'), findsOneWidget);
      expect(find.text('Daily Evening Review Reminders'), findsOneWidget);
      expect(find.text('Goal Progress Alerts'), findsOneWidget);
    });
  });
}
