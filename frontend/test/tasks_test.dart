import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/domain/auth_state.dart';
import 'package:frontend/features/auth/domain/user_model.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/tasks/data/tasks_api.dart';
import 'package:frontend/features/tasks/data/tasks_repository.dart';
import 'package:frontend/features/tasks/domain/category_model.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';
import 'package:frontend/features/tasks/domain/tasks_state.dart';
import 'package:frontend/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:frontend/features/tasks/presentation/widgets/task_card.dart';

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

    return (
      tasks: List<TaskModel>.from(_tasks),
      metrics: TaskMetricsModel(
        total: totalCount,
        completed: completedCount,
        pending: pendingCount,
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
    DateTime? deadline,
  }) async {
    final newTask = TaskModel(
      id: 'task-${_tasks.length + 1}',
      userId: 'user-1',
      title: title,
      description: description,
      priority: priority,
      status: TaskStatus.pending,
      categoryId: categoryId,
      deadline: deadline,
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
    DateTime? deadline,
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
      deadline: deadline ?? old.deadline,
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
              fullName: 'Utkarsh Pal',
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
  Future<void> logout() async {}
}

void main() {
  testWidgets('TasksScreen displays empty state when no tasks exist', (WidgetTester tester) async {
    final fakeRepo = FakeTasksRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksRepositoryProvider.overrideWithValue(fakeRepo),
          authControllerProvider.overrideWith((ref) => FakeAuthController()),
        ],
        child: const MaterialApp(
          home: TasksScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('Create your first task to get started.'), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
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
}
