import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/reminder_model.dart';

final remindersApiProvider = Provider<RemindersApi>((ref) {
  final dio = ref.watch(dioProvider);
  return RemindersApi(dio);
});

class RemindersApi {
  final Dio _dio;

  RemindersApi(this._dio);

  Future<ReminderModel> createReminder({
    required String taskId,
    required DateTime remindAt,
    int? notificationId,
  }) async {
    final payload = <String, dynamic>{
      'task_id': taskId,
      'remind_at': remindAt.toUtc().toIso8601String(),
      if (notificationId != null) 'notification_id': notificationId,
    };

    final response = await _dio.post(
      ApiEndpoints.reminders,
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return ReminderModel.fromJson(data);
  }

  Future<List<ReminderModel>> getReminders({
    String? taskId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (taskId != null) queryParams['task_id'] = taskId;
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      ApiEndpoints.reminders,
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final list = data['reminders'] as List<dynamic>;
    return list.map((r) => ReminderModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<ReminderModel> getReminder(String id) async {
    final response = await _dio.get('${ApiEndpoints.reminders}/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return ReminderModel.fromJson(data);
  }

  Future<ReminderModel> updateReminder(
    String id, {
    DateTime? remindAt,
    String? status,
    int? notificationId,
  }) async {
    final payload = <String, dynamic>{};
    if (remindAt != null) payload['remind_at'] = remindAt.toUtc().toIso8601String();
    if (status != null) payload['status'] = status;
    if (notificationId != null) payload['notification_id'] = notificationId;

    final response = await _dio.put(
      '${ApiEndpoints.reminders}/$id',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return ReminderModel.fromJson(data);
  }

  Future<void> deleteReminder(String id) async {
    await _dio.delete('${ApiEndpoints.reminders}/$id');
  }
}
