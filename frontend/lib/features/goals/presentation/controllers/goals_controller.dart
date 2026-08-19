import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/goals/data/goals_repository.dart';
import 'package:frontend/features/goals/domain/goal_model.dart';
import 'package:frontend/features/tasks/presentation/controllers/tasks_controller.dart';

class GoalsState {
  final List<GoalModel> goals;
  final bool isLoading;
  final bool isSaving;
  final GoalModel? selectedGoal;
  final GoalStatus? selectedStatusFilter; // null = all
  final String? errorMessage;

  const GoalsState({
    this.goals = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.selectedGoal,
    this.selectedStatusFilter,
    this.errorMessage,
  });

  List<GoalModel> get filteredGoals {
    if (selectedStatusFilter == null) return goals;
    return goals.where((g) => g.status == selectedStatusFilter).toList();
  }

  int get totalCount => goals.length;
  int get inProgressCount => goals.where((g) => g.status == GoalStatus.inProgress).length;
  int get completedCount => goals.where((g) => g.status == GoalStatus.completed).length;

  GoalsState copyWith({
    List<GoalModel>? goals,
    bool? isLoading,
    bool? isSaving,
    GoalModel? selectedGoal,
    GoalStatus? selectedStatusFilter,
    bool clearStatusFilter = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      selectedStatusFilter: clearStatusFilter
          ? null
          : (selectedStatusFilter ?? this.selectedStatusFilter),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final goalsControllerProvider =
    StateNotifierProvider<GoalsController, GoalsState>((ref) {
  final repo = ref.watch(goalsRepositoryProvider);
  final tasksNotifier = ref.read(tasksControllerProvider.notifier);
  return GoalsController(repo, tasksNotifier);
});

class GoalsController extends StateNotifier<GoalsState> {
  final GoalsRepository _goalsRepository;
  final TasksController _tasksController;

  GoalsController(this._goalsRepository, this._tasksController)
      : super(const GoalsState()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final goals = await _goalsRepository.getGoals(
        status: state.selectedStatusFilter?.apiValue,
      );
      state = state.copyWith(
        isLoading: false,
        goals: goals,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractError(e, 'Failed to load goals.'),
      );
    }
  }

  void selectFilter(GoalStatus? status) {
    if (state.selectedStatusFilter == status) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(selectedStatusFilter: status);
    }
    loadGoals();
  }

  Future<void> loadGoalDetail(String goalId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final detail = await _goalsRepository.getGoal(goalId);
      state = state.copyWith(
        isLoading: false,
        selectedGoal: detail,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractError(e, 'Failed to load goal details.'),
      );
    }
  }

  Future<bool> createGoal(Map<String, dynamic> payload) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final created = await _goalsRepository.createGoal(payload);
      state = state.copyWith(
        isSaving: false,
        goals: [created, ...state.goals],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _extractError(e, 'Failed to create goal.'),
      );
      return false;
    }
  }

  Future<bool> updateGoal(String goalId, Map<String, dynamic> payload) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _goalsRepository.updateGoal(goalId, payload);
      final updatedList = state.goals.map((g) => g.id == goalId ? updated : g).toList();
      state = state.copyWith(
        isSaving: false,
        goals: updatedList,
        selectedGoal: updated,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _extractError(e, 'Failed to update goal.'),
      );
      return false;
    }
  }

  Future<bool> deleteGoal(String goalId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _goalsRepository.deleteGoal(goalId);
      final updatedList = state.goals.where((g) => g.id != goalId).toList();
      state = state.copyWith(
        isSaving: false,
        goals: updatedList,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _extractError(e, 'Failed to delete goal.'),
      );
      return false;
    }
  }

  Future<bool> addMilestone(String goalId, Map<String, dynamic> payload) async {
    try {
      await _goalsRepository.addMilestone(goalId, payload);
      await loadGoalDetail(goalId);
      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractError(e, 'Failed to add milestone.'),
      );
      return false;
    }
  }

  Future<bool> toggleMilestone(String goalId, String milestoneId) async {
    try {
      await _goalsRepository.toggleMilestone(goalId, milestoneId);
      await loadGoalDetail(goalId);
      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractError(e, 'Failed to toggle milestone.'),
      );
      return false;
    }
  }

  Future<bool> deleteMilestone(String goalId, String milestoneId) async {
    try {
      await _goalsRepository.deleteMilestone(goalId, milestoneId);
      await loadGoalDetail(goalId);
      await loadGoals();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractError(e, 'Failed to delete milestone.'),
      );
      return false;
    }
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
