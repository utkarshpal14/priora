import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_notification_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../reminders/data/reminders_repository.dart';
import '../../../reminders/domain/reminder_model.dart';
import '../../data/tasks_repository.dart';
import '../../domain/category_model.dart';
import '../../domain/task_model.dart';
import '../../domain/tasks_state.dart';

final tasksControllerProvider =
    StateNotifierProvider<TasksController, TasksState>((ref) {
  ref.watch(authControllerProvider);
  final repository = ref.watch(tasksRepositoryProvider);
  final remindersRepo = ref.watch(remindersRepositoryProvider);
  final notificationService = ref.watch(localNotificationServiceProvider);
  return TasksController(repository, remindersRepo, notificationService);
});

class TasksController extends StateNotifier<TasksState> {
  final TasksRepository _repository;
  final RemindersRepository _remindersRepository;
  final LocalNotificationService _notificationService;

  TasksController(
    this._repository,
    this._remindersRepository,
    this._notificationService,
  ) : super(const TasksState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categoriesFuture = _repository.getCategories();
      final tasksFuture = _repository.getTasks(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      final results = await Future.wait([categoriesFuture, tasksFuture]);
      final categories = results[0] as List<dynamic>;
      final taskData = results[1] as ({List<TaskModel> tasks, TaskMetricsModel metrics});

      state = state.copyWith(
        isLoading: false,
        categories: categories.cast(),
        tasks: taskData.tasks,
        metrics: taskData.metrics,
      );

      _syncLocalNotifications(taskData.tasks);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractError(e, 'Failed to load tasks.'),
      );
    }
  }

  Future<void> refreshTasks() async {
    try {
      final taskData = await _repository.getTasks(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(
        tasks: taskData.tasks,
        metrics: taskData.metrics,
      );
      _syncLocalNotifications(taskData.tasks);
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractError(e, 'Failed to refresh tasks.'),
      );
    }
  }

  Future<void> _syncLocalNotifications(List<TaskModel> tasks) async {
    try {
      final now = DateTime.now();
      for (final task in tasks) {
        if (task.isCompleted || task.status == TaskStatus.cancelled) {
          continue;
        }

        // 1. Sync active reminders (BUG-006, ENH-006)
        for (final rem in task.reminders) {
          if (rem.isScheduled && rem.remindAt.isAfter(now)) {
            final notifId = rem.notificationId ?? (rem.id.hashCode.abs() % 100000);
            await _notificationService.scheduleNotification(
              notificationId: notifId,
              title: '⏰ Reminder: ${task.title}',
              body: task.deadline != null
                  ? 'Deadline approaching: ${task.formattedDeadline}'
                  : 'Task reminder: ${task.title}',
              scheduledDate: rem.remindAt,
            );
          }
        }

        // 2. Sync upcoming overdue deadline notification (BUG-007)
        if (task.deadline != null) {
          if (task.deadline!.isAfter(now)) {
            final overdueNotifId = (task.id.hashCode + 9999).abs() % 100000;
            await _notificationService.scheduleNotification(
              notificationId: overdueNotifId,
              title: '⚠️ Task Overdue: ${task.title}',
              body: 'The deadline for "${task.title}" has passed.',
              scheduledDate: task.deadline!,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[TasksController] Sync notifications notice: $e');
    }
  }

  void setTabFilter(TaskTabFilter filter) {
    state = state.copyWith(tabFilter: filter);
  }

  void setPriorityFilter(TaskPriority? priority) {
    if (priority == null) {
      state = state.copyWith(clearPriorityFilter: true);
    } else {
      state = state.copyWith(priorityFilter: priority);
    }
  }

  void setCategoryFilter(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(categoryFilterId: categoryId);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    String? categoryId,
    String? goalId,
    String? milestoneId,
    DateTime? deadline,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    DateTime? remindAt,
    String? repeatType,
    int? repeatInterval,
    DateTime? repeatEndDate,
  }) async {
    state = state.copyWith(isCreating: true, clearError: true);
    try {
      final task = await _repository.createTask(
        title: title,
        description: description,
        priority: priority,
        categoryId: categoryId,
        goalId: goalId,
        milestoneId: milestoneId,
        deadline: deadline,
        scheduledStart: scheduledStart,
        scheduledEnd: scheduledEnd,
        repeatType: repeatType,
        repeatInterval: repeatInterval,
        repeatEndDate: repeatEndDate,
      );

      // If user selected a reminder, schedule local notification and persist on backend
      if (remindAt != null) {
        try {
          final notifId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
          if (remindAt.isAfter(DateTime.now())) {
            await _notificationService.scheduleNotification(
              notificationId: notifId,
              title: '⏰ Reminder: ${task.title}',
              body: task.deadline != null
                  ? 'Deadline approaching: ${task.formattedDeadline}'
                  : 'Task reminder: ${task.title}',
              scheduledDate: remindAt,
            );
          }
          await _remindersRepository.createReminder(
            taskId: task.id,
            remindAt: remindAt,
            notificationId: notifId,
          );
        } catch (err) {
          debugPrint('Reminder setup notice: $err');
        }
      }

      state = state.copyWith(isCreating: false);
      await refreshTasks();
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: _extractError(e, 'Failed to create task.'),
      );
      return false;
    }
  }

  Future<bool> addReminderToTask({
    required String taskId,
    required String taskTitle,
    required DateTime remindAt,
    String? formattedDeadline,
  }) async {
    try {
      final notifId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _notificationService.scheduleNotification(
        notificationId: notifId,
        title: '⏰ Reminder: $taskTitle',
        body: formattedDeadline != null
            ? 'Deadline approaching: $formattedDeadline'
            : 'Task reminder: $taskTitle',
        scheduledDate: remindAt,
      );
      await _remindersRepository.createReminder(
        taskId: taskId,
        remindAt: remindAt,
        notificationId: notifId,
      );
      await refreshTasks();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractError(e, 'Failed to set reminder.'),
      );
      return false;
    }
  }

  Future<bool> deleteReminder({
    required String taskId,
    required String reminderId,
    int? notificationId,
  }) async {
    try {
      if (notificationId != null) {
        await _notificationService.cancelNotification(notificationId);
      }
      await _remindersRepository.deleteReminder(reminderId);
      await refreshTasks();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractError(e, 'Failed to remove reminder.'),
      );
      return false;
    }
  }

  Future<bool> updateTask({
    required String taskId,
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
    final originalTasks = [...state.tasks];
    final originalMetrics = state.metrics;

    // Optimistic local update
    final index = state.tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final oldTask = state.tasks[index];
      CategoryModel? updatedCategory = oldTask.category;
      if (categoryId != null) {
        final matches = state.categories.where((c) => c.id == categoryId);
        if (matches.isNotEmpty) {
          updatedCategory = matches.first;
        }
      }

      final updatedTask = oldTask.copyWith(
        title: title ?? oldTask.title,
        description: description ?? oldTask.description,
        priority: priority ?? oldTask.priority,
        status: status ?? oldTask.status,
        categoryId: categoryId ?? oldTask.categoryId,
        category: updatedCategory,
        goalId: goalId ?? oldTask.goalId,
        milestoneId: milestoneId ?? oldTask.milestoneId,
        deadline: deadline ?? oldTask.deadline,
        scheduledStart: scheduledStart ?? oldTask.scheduledStart,
        scheduledEnd: scheduledEnd ?? oldTask.scheduledEnd,
        repeatType: repeatType ?? oldTask.repeatType,
        repeatInterval: repeatInterval ?? oldTask.repeatInterval,
        repeatEndDate: repeatEndDate ?? oldTask.repeatEndDate,
        updatedAt: DateTime.now(),
      );

      final newTasks = [...state.tasks];
      newTasks[index] = updatedTask;
      state = state.copyWith(tasks: newTasks);
    }

    try {
      final updated = await _repository.updateTask(
        taskId,
        title: title,
        description: description,
        priority: priority,
        status: status,
        categoryId: categoryId,
        goalId: goalId,
        milestoneId: milestoneId,
        deadline: deadline,
        scheduledStart: scheduledStart,
        scheduledEnd: scheduledEnd,
        repeatType: repeatType,
        repeatInterval: repeatInterval,
        repeatEndDate: repeatEndDate,
      );
      final finalTasks = state.tasks.map((t) => t.id == taskId ? updated : t).toList();
      state = state.copyWith(tasks: finalTasks);
      if (status == TaskStatus.completed && updated.isRecurring) {
        await refreshTasks();
      } else {
        _syncLocalNotifications(finalTasks);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        tasks: originalTasks,
        metrics: originalMetrics,
        errorMessage: _extractError(e, 'Failed to update task.'),
      );
      return false;
    }
  }

  Future<void> toggleTaskCompletion(TaskModel task) async {
    final originalTasks = [...state.tasks];
    final originalMetrics = state.metrics;
    final willComplete = !task.isCompleted;

    // Optimistic UI state update
    final updatedTasks = state.tasks.map((t) {
      if (t.id == task.id) {
        return t.copyWith(
          status: willComplete ? TaskStatus.completed : TaskStatus.pending,
          completedAt: willComplete ? DateTime.now() : null,
        );
      }
      return t;
    }).toList();

    final overdueCount = updatedTasks.where((t) => t.isOverdue).length;
    final dueTodayCount = updatedTasks.where((t) => t.isDueToday).length;
    final updatedMetrics = TaskMetricsModel(
      total: state.metrics.total,
      completed: willComplete
          ? state.metrics.completed + 1
          : (state.metrics.completed > 0 ? state.metrics.completed - 1 : 0),
      pending: willComplete
          ? (state.metrics.pending > 0 ? state.metrics.pending - 1 : 0)
          : state.metrics.pending + 1,
      overdue: overdueCount,
      dueToday: dueTodayCount,
    );

    state = state.copyWith(tasks: updatedTasks, metrics: updatedMetrics);

    // Auto-Cancel Rule: Clear local notifications when task is completed
    if (willComplete) {
      final notifIds = task.reminders
          .map((r) => r.notificationId ?? (r.id.hashCode.abs() % 100000))
          .toList();
      if (notifIds.isNotEmpty) {
        _notificationService.cancelTaskNotifications(notifIds);
      }
    }

    try {
      if (willComplete) {
        await _repository.completeTask(task.id);
        if (task.isRecurring) {
          await refreshTasks();
        }
      } else {
        await _repository.reopenTask(task.id);
      }
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(
        tasks: originalTasks,
        metrics: originalMetrics,
        errorMessage: _extractError(e, 'Failed to update task status.'),
      );
    }
  }

  Future<void> deleteTask(String taskId) async {
    final originalTasks = [...state.tasks];
    final originalMetrics = state.metrics;
    final targetTask = state.tasks.firstWhere((t) => t.id == taskId, orElse: () => state.tasks.first);
    final wasCompleted = targetTask.isCompleted;

    // Optimistic removal
    final updatedTasks = state.tasks.where((t) => t.id != taskId).toList();
    final overdueCount = updatedTasks.where((t) => t.isOverdue).length;
    final dueTodayCount = updatedTasks.where((t) => t.isDueToday).length;
    final updatedMetrics = TaskMetricsModel(
      total: state.metrics.total > 0 ? state.metrics.total - 1 : 0,
      completed: wasCompleted
          ? (state.metrics.completed > 0 ? state.metrics.completed - 1 : 0)
          : state.metrics.completed,
      pending: !wasCompleted
          ? (state.metrics.pending > 0 ? state.metrics.pending - 1 : 0)
          : state.metrics.pending,
      overdue: overdueCount,
      dueToday: dueTodayCount,
    );

    state = state.copyWith(tasks: updatedTasks, metrics: updatedMetrics);

    // Auto-Cancel Rule: Clear local alarms when task is deleted
    final notifIds = targetTask.reminders
        .map((r) => r.notificationId ?? (r.id.hashCode.abs() % 100000))
        .toList();
    if (notifIds.isNotEmpty) {
      _notificationService.cancelTaskNotifications(notifIds);
    }

    try {
      await _repository.deleteTask(taskId);
    } catch (e) {
      state = state.copyWith(
        tasks: originalTasks,
        metrics: originalMetrics,
        errorMessage: _extractError(e, 'Failed to delete task.'),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _extractError(dynamic error, String fallback) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['detail'] != null) {
          return responseData['detail'].toString();
        }
        if (responseData['message'] != null) {
          return responseData['message'].toString();
        }
      }
    }
    return fallback;
  }
}
