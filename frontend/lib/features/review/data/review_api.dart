import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/review/domain/review_model.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

final reviewApiProvider = Provider<ReviewApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ReviewApi(dio);
});

class ReviewApi {
  final Dio _dio;

  ReviewApi(this._dio);

  Future<ReviewSummaryModel> getDailyReview({String? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) queryParams['date'] = date;

    final response = await _dio.get(
      '${ApiEndpoints.baseUrl}/review/daily',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return ReviewSummaryModel.fromJson(data);
  }

  Future<List<TaskModel>> batchReschedule(List<RescheduleItemModel> items) async {
    final payload = {
      'items': items.map((i) => i.toJson()).toList(),
    };

    final response = await _dio.post(
      '${ApiEndpoints.baseUrl}/review/batch-reschedule',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final rawTasks = data['updated_tasks'] as List<dynamic>? ?? [];
    return rawTasks.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList();
  }
}
