import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/features/attachments/data/attachments_repository.dart';
import 'package:frontend/features/attachments/domain/attachment_model.dart';
import 'package:frontend/features/attachments/presentation/controllers/attachments_controller.dart';
import 'package:frontend/features/attachments/presentation/widgets/resource_section_widget.dart';
import 'package:frontend/features/goals/domain/goal_model.dart';
import 'package:frontend/features/goals/presentation/widgets/goal_card.dart';
import 'package:frontend/features/tasks/domain/category_model.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';
import 'package:frontend/features/tasks/presentation/widgets/task_card.dart';
import 'package:dio/dio.dart';
import 'package:frontend/features/goals/data/goals_api.dart';
import 'package:frontend/features/goals/data/goals_repository.dart';
import 'package:frontend/features/tasks/data/tasks_api.dart';
import 'package:frontend/features/tasks/data/tasks_repository.dart';
import 'package:frontend/features/tasks/domain/tasks_state.dart';

import 'package:frontend/features/reminders/data/reminders_api.dart';
import 'package:frontend/features/reminders/data/reminders_repository.dart';
import 'package:frontend/features/reminders/domain/reminder_model.dart';

class FakeRemindersRepository extends RemindersRepository {
  FakeRemindersRepository() : super(RemindersApi(Dio()));
  @override
  Future<List<ReminderModel>> getReminders({String? taskId, String? status}) async => [];
}

class FakeTasksRepository extends TasksRepository {
  FakeTasksRepository() : super(TasksApi(Dio()));
  @override
  Future<({List<TaskModel> tasks, TaskMetricsModel metrics})> getTasks({String? search, String? categoryId, String? priority, String? status}) async {
    return (tasks: <TaskModel>[], metrics: const TaskMetricsModel());
  }
  @override
  Future<List<CategoryModel>> getCategories() async => [];
}

class FakeGoalsRepository extends GoalsRepository {
  FakeGoalsRepository() : super(GoalsApi(Dio()));
  @override
  Future<List<GoalModel>> getGoals({String? status, String? categoryId}) async => [];
}

class FakeAttachmentsRepository implements AttachmentsRepository {
  final List<AttachmentModel> items = [];

  @override
  Future<AttachmentModel> uploadAttachment({
    required List<int> fileBytes,
    required String filename,
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? name,
    String? tags,
    bool isPinned = false,
  }) async {
    final att = AttachmentModel(
      id: 'att-${items.length + 1}',
      userId: 'user-1',
      taskId: taskId,
      goalId: goalId,
      milestoneId: milestoneId,
      type: filename.endsWith('.png') ? 'IMAGE' : 'DOCUMENT',
      sourceType: 'UPLOAD',
      name: name ?? filename,
      originalFilename: filename,
      url: '/uploads/user-1/$filename',
      tags: tags,
      fileSizeBytes: fileBytes.length,
      isPinned: isPinned,
      createdAt: DateTime.now(),
    );
    items.add(att);
    return att;
  }

  @override
  Future<AttachmentModel> addLink({
    required String name,
    required String url,
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? tags,
    bool isPinned = false,
  }) async {
    final att = AttachmentModel(
      id: 'att-${items.length + 1}',
      userId: 'user-1',
      taskId: taskId,
      goalId: goalId,
      milestoneId: milestoneId,
      type: 'LINK',
      sourceType: 'LINK',
      name: name,
      url: url,
      domain: 'github.com',
      siteName: 'GitHub',
      tags: tags,
      isPinned: isPinned,
      createdAt: DateTime.now(),
    );
    items.add(att);
    return att;
  }

  @override
  Future<AttachmentModel> addNote({
    required String name,
    required String content,
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? tags,
    bool isPinned = false,
  }) async {
    final att = AttachmentModel(
      id: 'att-${items.length + 1}',
      userId: 'user-1',
      taskId: taskId,
      goalId: goalId,
      milestoneId: milestoneId,
      type: 'NOTE',
      sourceType: 'NOTE',
      name: name,
      content: content,
      tags: tags,
      isPinned: isPinned,
      createdAt: DateTime.now(),
    );
    items.add(att);
    return att;
  }

  @override
  Future<List<AttachmentModel>> listAttachments({
    String? taskId,
    String? goalId,
    String? milestoneId,
    String? tag,
  }) async {
    return items.where((a) {
      if (taskId != null && a.taskId != taskId) return false;
      if (goalId != null && a.goalId != goalId) return false;
      if (milestoneId != null && a.milestoneId != milestoneId) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<AttachmentModel>> searchAttachments(String query, {String? tag, String? type}) async {
    return items.where((a) => a.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<AttachmentModel> togglePin(String attachmentId) async {
    final index = items.indexWhere((a) => a.id == attachmentId);
    final updated = items[index].copyWith(isPinned: !items[index].isPinned);
    items[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    items.removeWhere((a) => a.id == attachmentId);
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AttachmentModel Tests', () {
    test('Formatted size and type helper properties work accurately', () {
      const att = AttachmentModel(
        id: 'att-1',
        userId: 'u-1',
        type: 'IMAGE',
        name: 'Screenshot.png',
        fileSizeBytes: 1572864, // 1.5 MB
        tags: 'DSA, Array, Placement',
      );

      assert(att.isImage == true);
      assert(att.isDocument == false);
      assert(att.isLink == false);
      assert(att.formattedSize == '1.5 MB');
      assert(att.tagsList.length == 3);
      assert(att.tagsList[0] == 'DSA');
    });
  });

  group('ResourceSectionWidget & Card Badges Tests', () {
    testWidgets('ResourceSectionWidget renders section title, action buttons, and items', (tester) async {
      final fakeRepo = FakeAttachmentsRepository();
      fakeRepo.items.add(
        const AttachmentModel(
          id: 'att-1',
          userId: 'u-1',
          taskId: 'task-1',
          type: 'LINK',
          name: 'Striver A2Z Sheet',
          url: 'https://github.com/takeUforward',
          domain: 'github.com',
          siteName: 'GitHub',
          tags: 'DSA, Placement',
        ),
      );

      final key = const EntityKey(taskId: 'task-1');
      final container = ProviderContainer(
        overrides: [
          attachmentsRepositoryProvider.overrideWithValue(fakeRepo),
          tasksRepositoryProvider.overrideWithValue(FakeTasksRepository()),
          goalsRepositoryProvider.overrideWithValue(FakeGoalsRepository()),
          remindersRepositoryProvider.overrideWithValue(FakeRemindersRepository()),
        ],
      );
      await container.read(attachmentsControllerProvider(key).notifier).loadAttachments();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ResourceSectionWidget(taskId: 'task-1'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resources & Attachments'), findsOneWidget);
      expect(find.text('Striver A2Z Sheet'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('#DSA'), findsOneWidget);
    });

    testWidgets('TaskCard displays attachment count badge when task has attachments', (tester) async {
      final taskWithAtts = TaskModel(
        id: 't-1',
        userId: 'u-1',
        title: 'OS Notes Task',
        attachmentCount: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: taskWithAtts,
              onToggleComplete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.attach_file_rounded), findsOneWidget);
    });

    testWidgets('GoalCard displays attachment count badge when goal has attachments', (tester) async {
      final goalWithAtts = GoalModel(
        id: 'g-1',
        userId: 'u-1',
        title: 'Placement Roadmap',
        attachmentCount: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalCard(
              goal: goalWithAtts,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('4 Resources'), findsOneWidget);
      expect(find.byIcon(Icons.attach_file_rounded), findsOneWidget);
    });
  });
}
