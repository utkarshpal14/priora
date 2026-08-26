import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/category_model.dart';
import '../domain/task_model.dart';
import '../domain/tasks_state.dart';

final tasksApiProvider = Provider<TasksApi>((ref) {
  final dio = ref.watch(dioProvider);
  return TasksApi(dio);
});

class TasksApi {
  final Dio _dio;

  TasksApi(this._dio);

  Future<({List<TaskModel> tasks, TaskMetricsModel metrics})> getTasks({
    String? status,
    String? priority,
    String? categoryId,
    String? search,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dio.get(
      ApiEndpoints.tasks,
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final rawTasks = data['tasks'] as List<dynamic>;
    final rawMetrics = data['metrics'] as Map<String, dynamic>;

    final tasks = rawTasks.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList();
    final metrics = TaskMetricsModel.fromJson(rawMetrics);

    return (tasks: tasks, metrics: metrics);
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
    String? repeatType,
    int? repeatInterval,
    DateTime? repeatEndDate,
  }) async {
    final payload = <String, dynamic>{
      'title': title.trim(),
      'priority': priority.apiValue,
    };
    if (description != null && description.isNotEmpty) {
      payload['description'] = description.trim();
    }
    if (categoryId != null) {
      payload['category_id'] = categoryId;
    }
    if (goalId != null) {
      payload['goal_id'] = goalId;
    }
    if (milestoneId != null) {
      payload['milestone_id'] = milestoneId;
    }
    if (deadline != null) {
      payload['deadline'] = deadline.toUtc().toIso8601String();
    }
    if (scheduledStart != null) {
      payload['scheduled_start'] = scheduledStart.toUtc().toIso8601String();
    }
    if (scheduledEnd != null) {
      payload['scheduled_end'] = scheduledEnd.toUtc().toIso8601String();
    }
    if (repeatType != null) {
      payload['repeat_type'] = repeatType;
    }
    if (repeatInterval != null) {
      payload['repeat_interval'] = repeatInterval;
    }
    if (repeatEndDate != null) {
      payload['repeat_end_date'] = repeatEndDate.toUtc().toIso8601String();
    }

    final response = await _dio.post(
      ApiEndpoints.tasks,
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return TaskModel.fromJson(data);
  }

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
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title.trim();
    if (description != null) payload['description'] = description.trim();
    if (priority != null) payload['priority'] = priority.apiValue;
    if (status != null) payload['status'] = status.apiValue;
    if (categoryId != null) payload['category_id'] = categoryId;
    if (goalId != null) payload['goal_id'] = goalId;
    if (milestoneId != null) payload['milestone_id'] = milestoneId;
    if (deadline != null) payload['deadline'] = deadline.toUtc().toIso8601String();
    if (scheduledStart != null) payload['scheduled_start'] = scheduledStart.toUtc().toIso8601String();
    if (scheduledEnd != null) payload['scheduled_end'] = scheduledEnd.toUtc().toIso8601String();
    if (repeatType != null) payload['repeat_type'] = repeatType;
    if (repeatInterval != null) payload['repeat_interval'] = repeatInterval;
    if (repeatEndDate != null) payload['repeat_end_date'] = repeatEndDate.toUtc().toIso8601String();

    final response = await _dio.put(
      '${ApiEndpoints.tasks}/$taskId',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return TaskModel.fromJson(data);
  }

  Future<TaskModel> completeTask(String taskId) async {
    final response = await _dio.patch('${ApiEndpoints.tasks}/$taskId/complete');
    final data = response.data['data'] as Map<String, dynamic>;
    return TaskModel.fromJson(data);
  }

  Future<TaskModel> reopenTask(String taskId) async {
    final response = await _dio.patch('${ApiEndpoints.tasks}/$taskId/reopen');
    final data = response.data['data'] as Map<String, dynamic>;
    return TaskModel.fromJson(data);
  }

  Future<void> deleteTask(String taskId) async {
    await _dio.delete('${ApiEndpoints.tasks}/$taskId');
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.get(ApiEndpoints.categories);
    final list = response.data['data'] as List<dynamic>;
    return list.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    String color = '#2D6A4F',
    String? icon,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.categories,
      data: {
        'name': name.trim(),
        'color': color,
        'icon': icon,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return CategoryModel.fromJson(data);
  }
}
