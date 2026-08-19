import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/planner/data/planner_api.dart';
import 'package:frontend/features/planner/domain/planner_model.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  final api = ref.watch(plannerApiProvider);
  return PlannerRepository(api);
});

class PlannerRepository {
  final PlannerApi _api;

  PlannerRepository(this._api);

  Future<DailyPlanModel> getDailyPlan({String? date}) async {
    return _api.getDailyPlan(date: date);
  }

  Future<WeeklyPlanModel> getWeeklyPlan({String? startDate}) async {
    return _api.getWeeklyPlan(startDate: startDate);
  }

  Future<TaskModel> moveToToday(String taskId) async {
    return _api.moveToToday(taskId);
  }

  Future<TaskModel> scheduleTask(String taskId, DateTime? deadline) async {
    return _api.scheduleTask(taskId, deadline);
  }
}
