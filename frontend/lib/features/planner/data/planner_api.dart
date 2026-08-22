import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/planner/domain/planner_model.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

final plannerApiProvider = Provider<PlannerApi>((ref) {
  final dio = ref.watch(dioProvider);
  return PlannerApi(dio);
});

class PlannerApi {
  final Dio _dio;

  PlannerApi(this._dio);

  Future<DailyPlanModel> getDailyPlan({String? date}) async {
    final queryParams = <String, dynamic>{
      'tz_offset': DateTime.now().timeZoneOffset.inMinutes,
    };
    if (date != null) queryParams['date'] = date;

    final response = await _dio.get(
      ApiEndpoints.dailyPlanner,
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return DailyPlanModel.fromJson(data);
  }

  Future<WeeklyPlanModel> getWeeklyPlan({String? startDate}) async {
    final queryParams = <String, dynamic>{
      'tz_offset': DateTime.now().timeZoneOffset.inMinutes,
    };
    if (startDate != null) queryParams['start_date'] = startDate;

    final response = await _dio.get(
      '${ApiEndpoints.baseUrl}/planner/week',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return WeeklyPlanModel.fromJson(data);
  }

  Future<TaskModel> moveToToday(String taskId) async {
    final response = await _dio.post(
      '${ApiEndpoints.baseUrl}/planner/move-to-today',
      data: {'task_id': taskId},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return TaskModel.fromJson(data);
  }

  Future<TaskModel> scheduleTask(String taskId, DateTime? deadline) async {
    final payload = <String, dynamic>{
      'task_id': taskId,
      'deadline': deadline?.toUtc().toIso8601String(),
    };

    final response = await _dio.post(
      '${ApiEndpoints.baseUrl}/planner/schedule',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return TaskModel.fromJson(data);
  }

  Future<TaskSessionModel> createSession({
    required String taskId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  }) async {
    final payload = {
      'task_id': taskId,
      'scheduled_start': scheduledStart.toUtc().toIso8601String(),
      'scheduled_end': scheduledEnd.toUtc().toIso8601String(),
    };

    final response = await _dio.post(
      '${ApiEndpoints.baseUrl}/planner/sessions',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return TaskSessionModel.fromJson(data);
  }

  Future<TaskSessionModel> updateSession({
    required String sessionId,
    String? taskId,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
  }) async {
    final payload = <String, dynamic>{};
    if (taskId != null) payload['task_id'] = taskId;
    if (scheduledStart != null) {
      payload['scheduled_start'] = scheduledStart.toUtc().toIso8601String();
    }
    if (scheduledEnd != null) {
      payload['scheduled_end'] = scheduledEnd.toUtc().toIso8601String();
    }

    final response = await _dio.put(
      '${ApiEndpoints.baseUrl}/planner/sessions/$sessionId',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return TaskSessionModel.fromJson(data);
  }

  Future<void> deleteSession(String sessionId) async {
    await _dio.delete('${ApiEndpoints.baseUrl}/planner/sessions/$sessionId');
  }
}
