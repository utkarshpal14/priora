import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/goals/domain/goal_model.dart';

final goalsApiProvider = Provider<GoalsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return GoalsApi(dio);
});

class GoalsApi {
  final Dio _dio;

  GoalsApi(this._dio);

  Future<List<GoalModel>> getGoals({String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      '${ApiEndpoints.baseUrl}/goals',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final rawGoals = data['goals'] as List<dynamic>? ?? [];
    return rawGoals.map((g) => GoalModel.fromJson(g as Map<String, dynamic>)).toList();
  }

  Future<GoalModel> getGoal(String id) async {
    final response = await _dio.get('${ApiEndpoints.baseUrl}/goals/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return GoalModel.fromJson(data);
  }

  Future<GoalModel> createGoal(Map<String, dynamic> payload) async {
    final response = await _dio.post(
      '${ApiEndpoints.baseUrl}/goals',
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return GoalModel.fromJson(data);
  }

  Future<GoalModel> updateGoal(String id, Map<String, dynamic> payload) async {
    final response = await _dio.put(
      '${ApiEndpoints.baseUrl}/goals/$id',
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return GoalModel.fromJson(data);
  }

  Future<void> deleteGoal(String id) async {
    await _dio.delete('${ApiEndpoints.baseUrl}/goals/$id');
  }

  Future<GoalMilestoneModel> addMilestone(
    String goalId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post(
      '${ApiEndpoints.baseUrl}/goals/$goalId/milestones',
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return GoalMilestoneModel.fromJson(data);
  }

  Future<GoalMilestoneModel> toggleMilestone(
    String goalId,
    String milestoneId,
  ) async {
    final response = await _dio.patch(
      '${ApiEndpoints.baseUrl}/goals/$goalId/milestones/$milestoneId/toggle',
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return GoalMilestoneModel.fromJson(data);
  }

  Future<void> deleteMilestone(String goalId, String milestoneId) async {
    await _dio.delete('${ApiEndpoints.baseUrl}/goals/$goalId/milestones/$milestoneId');
  }
}
