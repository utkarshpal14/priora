import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/category_model.dart';
import '../domain/task_model.dart';
import '../domain/tasks_state.dart';
import 'tasks_api.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final api = ref.watch(tasksApiProvider);
  return TasksRepository(api);
});

class TasksRepository {
  final TasksApi _api;

  TasksRepository(this._api);

  Future<({List<TaskModel> tasks, TaskMetricsModel metrics})> getTasks({
    String? status,
    String? priority,
    String? categoryId,
    String? search,
  }) {
    return _api.getTasks(
      status: status,
      priority: priority,
      categoryId: categoryId,
      search: search,
    );
  }

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
  }) {
    return _api.createTask(
      title: title,
      description: description,
      priority: priority,
      categoryId: categoryId,
      goalId: goalId,
      milestoneId: milestoneId,
      deadline: deadline,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
    );
  }

  Future<TaskModel> updateTask(
    String taskId, {
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    String? categoryId,
    DateTime? deadline,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
  }) {
    return _api.updateTask(
      taskId,
      title: title,
      description: description,
      priority: priority,
      status: status,
      categoryId: categoryId,
      deadline: deadline,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
    );
  }

  Future<TaskModel> completeTask(String taskId) {
    return _api.completeTask(taskId);
  }

  Future<TaskModel> reopenTask(String taskId) {
    return _api.reopenTask(taskId);
  }

  Future<void> deleteTask(String taskId) {
    return _api.deleteTask(taskId);
  }

  Future<List<CategoryModel>> getCategories() {
    return _api.getCategories();
  }

  Future<CategoryModel> createCategory({
    required String name,
    String color = '#2D6A4F',
    String? icon,
  }) {
    return _api.createCategory(name: name, color: color, icon: icon);
  }
}
