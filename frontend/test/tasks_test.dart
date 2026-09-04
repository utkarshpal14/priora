import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/domain/auth_state.dart';
import 'package:frontend/features/auth/domain/user_model.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/reminders/data/reminders_api.dart';
import 'package:frontend/features/reminders/data/reminders_repository.dart';
import 'package:frontend/features/reminders/domain/reminder_model.dart';
import 'package:frontend/features/tasks/data/tasks_api.dart';
import 'package:frontend/features/tasks/data/tasks_repository.dart';
import 'package:frontend/features/tasks/domain/category_model.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';
import 'package:frontend/features/tasks/domain/tasks_state.dart';
import 'package:frontend/features/attachments/data/attachments_api.dart';
import 'package:frontend/features/attachments/data/attachments_repository.dart';
import 'package:frontend/features/attachments/domain/attachment_model.dart';
import 'package:frontend/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:frontend/features/tasks/presentation/widgets/task_card.dart';

import 'package:frontend/features/goals/data/goals_api.dart';
import 'package:frontend/features/goals/data/goals_repository.dart';
import 'package:frontend/features/goals/domain/goal_model.dart';

class FakeGoalsRepository extends GoalsRepository {
  FakeGoalsRepository() : super(GoalsApi(Dio()));
  @override
  Future<List<GoalModel>> getGoals({String? status, String? categoryId}) async => [];
}

class FakeAttachmentsRepository extends AttachmentsRepository {
  FakeAttachmentsRepository() : super(AttachmentsApi(Dio()));
  @override
  Future<List<AttachmentModel>> listAttachments({String? taskId, String? goalId, String? milestoneId, String? tag}) async => [];
}

class FakeRemindersRepository extends RemindersRepository {
  final List<ReminderModel> _reminders = [];

  FakeRemindersRepository() : super(RemindersApi(Dio()));

  @override
  Future<ReminderModel> createReminder({
    required String taskId,
    required DateTime remindAt,
    int? notificationId,
  }) async {
    final newReminder = ReminderModel(
      id: 'rem-${_reminders.length + 1}',
      taskId: taskId,
      remindAt: remindAt,
      notificationId: notificationId ?? 1,
      status: 'SCHEDULED',
    );
    _reminders.add(newReminder);
    return newReminder;
  }

  @override
  Future<List<ReminderModel>> getReminders({String? taskId, String? status}) async {
    return _reminders;
  }

  @override
  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
  }
}

class FakeTasksRepository extends TasksRepository {
  final List<TaskModel> _tasks = [];
  final List<CategoryModel> _categories = [
    const CategoryModel(id: 'cat-1', userId: 'user-1', name: 'Personal', color: '#2D6A4F'),
    const CategoryModel(id: 'cat-2', userId: 'user-1', name: 'Work', color: '#1E40AF'),
  ];

  FakeTasksRepository() : super(TasksApi(Dio()));

  @override
  Future<({List<TaskModel> tasks, TaskMetricsModel metrics})> getTasks({
    String? status,
    String? priority,
    String? categoryId,
    String? search,
  }) async {
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final totalCount = _tasks.length;
    final pendingCount = totalCount - completedCount;
    final overdueCount = _tasks.where((t) => t.isOverdue).length;
    final dueTodayCount = _tasks.where((t) => t.isDueToday).length;

    return (
      tasks: List<TaskModel>.from(_tasks),
      metrics: TaskMetricsModel(
        total: totalCount,
        completed: completedCount,
        pending: pendingCount,
        overdue: overdueCount,
        dueToday: dueTodayCount,
      ),
    );
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    return _categories;
  }

  @override
  Future<TaskModel> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
    String? goalId,
    String? milestoneId,
    DateTime? deadline,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    String? repeatType,
    int? repeatInterval,
    DateTime? repeatEndDate,
  }) async {
    final newTask = TaskModel(
      id: 'task-${_tasks.length + 1}',
      userId: 'user-1',
      title: title,
      description: description,
      priority: priority,
      status: TaskStatus.pending,
      categoryId: categoryId,
      goalId: goalId,
      milestoneId: milestoneId,
      deadline: deadline,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      repeatType: repeatType ?? 'none',
      repeatInterval: repeatInterval ?? 1,
      repeatEndDate: repeatEndDate,
    );
    _tasks.add(newTask);
    return newTask;
  }

  @override
  Future<TaskModel> completeTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    final updated = _tasks[index].copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<TaskModel> reopenTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    final updated = _tasks[index].copyWith(
      status: TaskStatus.pending,
      completedAt: null,
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<TaskModel> updateTask(
    String taskId, {
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    String? categoryId,
    String? goalId,
    String? milestoneId,
    DateTime? deadline,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    String? repeatType,
    int? repeatInterval,
    DateTime? repeatEndDate,
  }) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    final old = _tasks[index];
    final category = categoryId != null
        ? _categories.cast<CategoryModel?>().firstWhere(
            (c) => c?.id == categoryId,
            orElse: () => null,
          )
        : old.category;

    final updated = old.copyWith(
      title: title ?? old.title,
      description: description ?? old.description,
      priority: priority ?? old.priority,
      status: status ?? old.status,
      categoryId: categoryId ?? old.categoryId,
      category: category,
      goalId: goalId ?? old.goalId,
      milestoneId: milestoneId ?? old.milestoneId,
      deadline: deadline ?? old.deadline,
      scheduledStart: scheduledStart ?? old.scheduledStart,
      scheduledEnd: scheduledEnd ?? old.scheduledEnd,
      repeatType: repeatType ?? old.repeatType,
      repeatInterval: repeatInterval ?? old.repeatInterval,
      repeatEndDate: repeatEndDate ?? old.repeatEndDate,
      updatedAt: DateTime.now(),
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
  }
}

class FakeAuthController extends StateNotifier<AuthState> implements AuthController {
  FakeAuthController()
      : super(
          const AuthState(
            status: AuthStatus.authenticated,
            user: UserModel(
              id: 'user-1',
              email: 'test@priora.app',
              fullName: 'Priora Tester',
            ),
          ),
        );

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> login({required String email, required String password}) async => true;

  @override
  Future<bool> loginWithGoogle() async => true;

  @override
  Future<bool> register({required String email, required String password, String? fullName}) async => true;

  @override
  Future<bool> verifyOtp({required String email, required String otpCode}) async => true;

  @override
  Future<({bool success, int cooldownSeconds, String message})> resendOtp({required String email}) async {
    return (success: true, cooldownSeconds: 60, message: 'New code sent.');
  }

  @override
  Future<({bool success, String message})> forgotPassword({required String email}) async {
    return (success: true, message: 'Reset code sent.');
  }

  @override
  Future<({bool success, String message})> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    return (success: true, message: 'Password reset.');
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('TasksScreen displays empty state when no tasks exist', (WidgetTester tester) async {
    final fakeRepo = FakeTasksRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksRepositoryProvider.overrideWithValue(fakeRepo),
          goalsRepositoryProvider.overrideWithValue(FakeGoalsRepository()),
          remindersRepositoryProvider.overrideWithValue(FakeRemindersRepository()),
          attachmentsRepositoryProvider.overrideWithValue(FakeAttachmentsRepository()),
          authControllerProvider.overrideWith((ref) => FakeAuthController()),
        ],
        child: const MaterialApp(
          home: TasksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No tasks'), findsOneWidget);
    expect(find.text('Create Task'), findsWidgets);
  });

  testWidgets('TasksScreen renders task cards and toggles completion', (WidgetTester tester) async {
    final fakeRepo = FakeTasksRepository();
    await fakeRepo.createTask(
      title: 'Review System Architecture',
      priority: TaskPriority.critical,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksRepositoryProvider.overrideWithValue(fakeRepo),
          goalsRepositoryProvider.overrideWithValue(FakeGoalsRepository()),
          remindersRepositoryProvider.overrideWithValue(FakeRemindersRepository()),
          attachmentsRepositoryProvider.overrideWithValue(FakeAttachmentsRepository()),
          authControllerProvider.overrideWith((ref) => FakeAuthController()),
        ],
        child: const MaterialApp(
          home: TasksScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify task title and priority badge
    expect(find.text('Review System Architecture'), findsOneWidget);
    expect(find.text('CRITICAL'), findsOneWidget);

    // Tap checkbox to complete task
    await tester.tap(find.byType(TaskCard));
    await tester.pump();
  });

  testWidgets('Tapping task opens EditTaskBottomSheet and saves changes', (WidgetTester tester) async {
    final fakeRepo = FakeTasksRepository();
    final task = await fakeRepo.createTask(
      title: 'Draft Project Specs',
      priority: TaskPriority.medium,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksRepositoryProvider.overrideWithValue(fakeRepo),
          goalsRepositoryProvider.overrideWithValue(FakeGoalsRepository()),
          remindersRepositoryProvider.overrideWithValue(FakeRemindersRepository()),
          attachmentsRepositoryProvider.overrideWithValue(FakeAttachmentsRepository()),
          authControllerProvider.overrideWith((ref) => FakeAuthController()),
        ],
        child: const MaterialApp(
          home: TasksScreen(),
        ),
      ),
    );
    await tester.pump();

    // Tap on task title to open edit sheet
    await tester.tap(find.text('Draft Project Specs'));
    await tester.pumpAndSettle();

    // Verify edit bottom sheet opens
    expect(find.text('Edit Task'), findsOneWidget);
    expect(find.text('Task Title'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    // Update title
    await tester.enterText(find.widgetWithText(TextFormField, 'Draft Project Specs'), 'Finalize Project Specs');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Verify updated title in list
    expect(find.text('Finalize Project Specs'), findsOneWidget);
  });

  testWidgets('Category dropdown filter filters tasks', (WidgetTester tester) async {
    final fakeRepo = FakeTasksRepository();
    await fakeRepo.createTask(
      title: 'Work Task Item',
      categoryId: 'cat-2', // Work
      priority: TaskPriority.high,
    );
    await fakeRepo.createTask(
      title: 'Personal Task Item',
      categoryId: 'cat-1', // Personal
      priority: TaskPriority.low,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksRepositoryProvider.overrideWithValue(fakeRepo),
          goalsRepositoryProvider.overrideWithValue(FakeGoalsRepository()),
          remindersRepositoryProvider.overrideWithValue(FakeRemindersRepository()),
          attachmentsRepositoryProvider.overrideWithValue(FakeAttachmentsRepository()),
          authControllerProvider.overrideWith((ref) => FakeAuthController()),
        ],
        child: const MaterialApp(
          home: TasksScreen(),
        ),
      ),
    );
    await tester.pump();

    // Both tasks visible initially
    expect(find.text('Work Task Item'), findsOneWidget);
    expect(find.text('Personal Task Item'), findsOneWidget);

    // Select Personal Category
    await tester.tap(find.text('All Categories'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Personal').last);
    await tester.pumpAndSettle();

    // Only Personal task visible
    expect(find.text('Personal Task Item'), findsOneWidget);
    expect(find.text('Work Task Item'), findsNothing);
  });

  testWidgets('Overdue tab and Smart Urgency Banner function properly', (WidgetTester tester) async {
    final fakeRepo = FakeTasksRepository();
    // 1 Overdue task
    await fakeRepo.createTask(
      title: 'Overdue Project Task',
      deadline: DateTime.now().subtract(const Duration(days: 2)),
      priority: TaskPriority.critical,
    );
    // 1 Future task
    await fakeRepo.createTask(
      title: 'Future Project Task',
      deadline: DateTime.now().add(const Duration(days: 3)),
      priority: TaskPriority.low,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksRepositoryProvider.overrideWithValue(fakeRepo),
          goalsRepositoryProvider.overrideWithValue(FakeGoalsRepository()),
          remindersRepositoryProvider.overrideWithValue(FakeRemindersRepository()),
          attachmentsRepositoryProvider.overrideWithValue(FakeAttachmentsRepository()),
          authControllerProvider.overrideWith((ref) => FakeAuthController()),
        ],
        child: const MaterialApp(
          home: TasksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify smart urgency banner appears
    expect(find.text('1 overdue task needs attention'), findsOneWidget);
    expect(find.text('View Tasks'), findsOneWidget);

    // Tap View Tasks in banner to switch to Overdue tab
    await tester.tap(find.text('View Tasks'));
    await tester.pumpAndSettle();

    // In Overdue tab: Overdue task is shown, future task is hidden
    expect(find.text('Overdue Project Task'), findsOneWidget);
    expect(find.text('Future Project Task'), findsNothing);
  });

  testWidgets('Overdue empty state renders celebration message when no overdue tasks', (WidgetTester tester) async {
    final fakeRepo = FakeTasksRepository();
    await fakeRepo.createTask(
      title: 'Future Task Only',
      deadline: DateTime.now().add(const Duration(days: 2)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksRepositoryProvider.overrideWithValue(fakeRepo),
          goalsRepositoryProvider.overrideWithValue(FakeGoalsRepository()),
          remindersRepositoryProvider.overrideWithValue(FakeRemindersRepository()),
          attachmentsRepositoryProvider.overrideWithValue(FakeAttachmentsRepository()),
          authControllerProvider.overrideWith((ref) => FakeAuthController()),
        ],
        child: const MaterialApp(
          home: TasksScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Overdue tab
    await tester.tap(find.text('Overdue'));
    await tester.pumpAndSettle();

    // Verify celebration empty state
    expect(find.text('🎉 No overdue tasks'), findsOneWidget);
    expect(find.textContaining("You're all caught up!"), findsOneWidget);
  });

  test('TaskModel.parseUtcDateTime safely parses UTC datetime strings without Z suffix into local time', () {
    final dtWithZ = TaskModel.parseUtcDateTime('2026-08-19T16:45:00Z');
    final dtWithoutZ = TaskModel.parseUtcDateTime('2026-08-19T16:45:00');
    final dtWithSpace = TaskModel.parseUtcDateTime('2026-08-19 16:45:00');

    expect(dtWithZ, isNotNull);
    expect(dtWithoutZ, isNotNull);
    expect(dtWithSpace, isNotNull);
    expect(dtWithZ, equals(dtWithoutZ));
    expect(dtWithZ, equals(dtWithSpace));
  });

  test('ReminderPreset.calculateRemindAt accurately computes preset offsets from deadline', () {
    final deadline = DateTime(2026, 8, 20, 18, 0); // 6:00 PM

    expect(
      ReminderPreset.fifteenMinutes.calculateRemindAt(deadline),
      equals(DateTime(2026, 8, 20, 17, 45)),
    );
    expect(
      ReminderPreset.thirtyMinutes.calculateRemindAt(deadline),
      equals(DateTime(2026, 8, 20, 17, 30)),
    );
    expect(
      ReminderPreset.oneHour.calculateRemindAt(deadline),
      equals(DateTime(2026, 8, 20, 17, 0)),
    );
    expect(
      ReminderPreset.threeHours.calculateRemindAt(deadline),
      equals(DateTime(2026, 8, 20, 15, 0)),
    );
    expect(
      ReminderPreset.oneDay.calculateRemindAt(deadline),
      equals(DateTime(2026, 8, 19, 18, 0)),
    );
  });

  testWidgets('TaskCard displays active reminder icon and text when reminder is scheduled', (WidgetTester tester) async {
    final task = TaskModel(
      id: 'task-rem-1',
      userId: 'user-1',
      title: 'Task with Active Reminder',
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      deadline: DateTime(2026, 8, 20, 18, 0),
      reminders: [
        ReminderModel(
          id: 'rem-1',
          taskId: 'task-rem-1',
          notificationId: 101,
          remindAt: DateTime(2026, 8, 20, 17, 0),
          status: 'SCHEDULED',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            onToggleComplete: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify reminder active bell icon is displayed
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    expect(find.text('Task with Active Reminder'), findsOneWidget);
  });

  test('TaskModel accurately parses recurring fields and computes recurrence properties', () {
    final recurringJson = {
      'id': 'rec-1',
      'user_id': 'user-1',
      'title': 'Daily Standup',
      'priority': 'HIGH',
      'status': 'PENDING',
      'repeat_type': 'daily',
      'repeat_interval': 1,
      'repeat_end_date': '2026-12-31T23:59:59Z',
    };

    final task = TaskModel.fromJson(recurringJson);
    expect(task.isRecurring, isTrue);
    expect(task.repeatType, equals('daily'));
    expect(task.repeatInterval, equals(1));
    expect(task.repeatLabel, equals('Daily'));
    expect(task.repeatEndDate, isNotNull);

    final weeklyTask = task.copyWith(repeatType: 'weekly', repeatInterval: 2);
    expect(weeklyTask.repeatLabel, equals('Every 2 weeks'));

    final nonRecurringTask = task.copyWith(repeatType: 'none');
    expect(nonRecurringTask.isRecurring, isFalse);
    expect(nonRecurringTask.repeatLabel, equals('Never'));
  });

  testWidgets('TaskCard displays recurring badge and repeat icon for recurring tasks', (WidgetTester tester) async {
    final task = TaskModel(
      id: 'task-recur-1',
      userId: 'user-1',
      title: 'Daily Code Review',
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      repeatType: 'daily',
      repeatInterval: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            onToggleComplete: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify repeat icon and Daily badge are displayed
    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Daily Code Review'), findsOneWidget);
  });

  testWidgets('TaskCard displays both recurring badge and active reminder bell icon for recurring task with reminder', (WidgetTester tester) async {
    final task = TaskModel(
      id: 'task-recur-rem-1',
      userId: 'user-1',
      title: 'Daily Standup Call',
      priority: TaskPriority.critical,
      status: TaskStatus.pending,
      repeatType: 'daily',
      repeatInterval: 1,
      reminders: [
        ReminderModel(
          id: 'rem-rec-1',
          taskId: 'task-recur-rem-1',
          notificationId: 54321,
          remindAt: DateTime.now().add(const Duration(hours: 24)),
          status: 'SCHEDULED',
        ),
      ],
    );

    expect(task.isRecurring, isTrue);
    expect(task.hasActiveReminder, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            onToggleComplete: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify both recurring and reminder indicators are shown
    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Daily Standup Call'), findsOneWidget);
  });
}


