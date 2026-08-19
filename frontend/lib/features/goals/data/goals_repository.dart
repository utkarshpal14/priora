import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/goals/data/goals_api.dart';
import 'package:frontend/features/goals/domain/goal_model.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  final api = ref.watch(goalsApiProvider);
  return GoalsRepository(api);
});

class GoalsRepository {
  final GoalsApi _api;

  GoalsRepository(this._api);

  Future<List<GoalModel>> getGoals({String? status}) async {
    return _api.getGoals(status: status);
  }

  Future<GoalModel> getGoal(String id) async {
    return _api.getGoal(id);
  }

  Future<GoalModel> createGoal(Map<String, dynamic> payload) async {
    return _api.createGoal(payload);
  }

  Future<GoalModel> updateGoal(String id, Map<String, dynamic> payload) async {
    return _api.updateGoal(id, payload);
  }

  Future<void> deleteGoal(String id) async {
    return _api.deleteGoal(id);
  }

  Future<GoalMilestoneModel> addMilestone(
    String goalId,
    Map<String, dynamic> payload,
  ) async {
    return _api.addMilestone(goalId, payload);
  }

  Future<GoalMilestoneModel> toggleMilestone(
    String goalId,
    String milestoneId,
  ) async {
    return _api.toggleMilestone(goalId, milestoneId);
  }

  Future<void> deleteMilestone(String goalId, String milestoneId) async {
    return _api.deleteMilestone(goalId, milestoneId);
  }
}
