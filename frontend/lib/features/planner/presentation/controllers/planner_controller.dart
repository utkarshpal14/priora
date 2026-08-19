import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:frontend/features/planner/data/planner_repository.dart';
import 'package:frontend/features/planner/domain/planner_model.dart';
import 'package:frontend/features/tasks/data/tasks_repository.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';
import 'package:frontend/features/tasks/presentation/controllers/tasks_controller.dart';

class PlannerState {
  final bool isLoading;
  final DateTime selectedDate;
  final DailyPlanModel? dailyPlan;
  final WeeklyPlanModel? weeklyPlan;
  final String? errorMessage;

  const PlannerState({
    this.isLoading = false,
    required this.selectedDate,
    this.dailyPlan,
    this.weeklyPlan,
    this.errorMessage,
  });

  bool get isViewingToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  PlannerState copyWith({
    bool? isLoading,
    DateTime? selectedDate,
    DailyPlanModel? dailyPlan,
    WeeklyPlanModel? weeklyPlan,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlannerState(
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      dailyPlan: dailyPlan ?? this.dailyPlan,
      weeklyPlan: weeklyPlan ?? this.weeklyPlan,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final plannerControllerProvider =
    StateNotifierProvider<PlannerController, PlannerState>((ref) {
  final plannerRepo = ref.watch(plannerRepositoryProvider);
  final tasksRepo = ref.watch(tasksRepositoryProvider);
  final tasksNotifier = ref.read(tasksControllerProvider.notifier);
  return PlannerController(plannerRepo, tasksRepo, tasksNotifier);
});

class PlannerController extends StateNotifier<PlannerState> {
  final PlannerRepository _plannerRepository;
  final TasksRepository _tasksRepository;
  final TasksController _tasksController;

  PlannerController(
    this._plannerRepository,
    this._tasksRepository,
    this._tasksController,
  ) : super(PlannerState(selectedDate: DateTime.now())) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(state.selectedDate);
      final dailyFuture = _plannerRepository.getDailyPlan(date: dateStr);
      final weeklyFuture = _plannerRepository.getWeeklyPlan();

      final results = await Future.wait([dailyFuture, weeklyFuture]);
      state = state.copyWith(
        isLoading: false,
        dailyPlan: results[0] as DailyPlanModel,
        weeklyPlan: results[1] as WeeklyPlanModel,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractError(e, 'Failed to load daily plan.'),
      );
    }
  }

  Future<void> selectDate(DateTime date) async {
    if (state.selectedDate.year == date.year &&
        state.selectedDate.month == date.month &&
        state.selectedDate.day == date.day) {
      return;
    }
    state = state.copyWith(selectedDate: date, isLoading: true, clearError: true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final plan = await _plannerRepository.getDailyPlan(date: dateStr);
      state = state.copyWith(isLoading: false, dailyPlan: plan);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractError(e, 'Failed to load plan for selected date.'),
      );
    }
  }

  Future<void> toggleTaskCompletion(TaskModel task) async {
    await _tasksController.toggleTaskCompletion(task);
    await loadData();
  }

  Future<void> startTask(TaskModel task) async {
    try {
      await _tasksRepository.updateTask(
        task.id,
        status: TaskStatus.inProgress,
      );
      await _tasksController.refreshTasks();
      await loadData();
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractError(e, 'Failed to start task.'),
      );
    }
  }

  Future<void> moveToToday(String taskId) async {
    try {
      await _plannerRepository.moveToToday(taskId);
      await _tasksController.refreshTasks();
      await loadData();
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractError(e, 'Failed to move task to today.'),
      );
    }
  }

  Future<void> scheduleTask(String taskId, DateTime newDeadline) async {
    try {
      await _plannerRepository.scheduleTask(taskId, newDeadline);
      await _tasksController.refreshTasks();
      await loadData();
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractError(e, 'Failed to schedule task.'),
      );
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
