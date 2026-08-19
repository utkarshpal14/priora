import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/planner/presentation/controllers/planner_controller.dart';
import 'package:frontend/features/review/data/review_repository.dart';
import 'package:frontend/features/review/domain/review_model.dart';
import 'package:frontend/features/tasks/presentation/controllers/tasks_controller.dart';

class ReviewState {
  final bool isLoading;
  final bool isSubmitting;
  final ReviewSummaryModel? summary;
  final Map<String, RescheduleItemModel> stagedActions;
  final String? errorMessage;
  final bool isCelebrationVisible;

  const ReviewState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.summary,
    this.stagedActions = const {},
    this.errorMessage,
    this.isCelebrationVisible = false,
  });

  bool get allTasksStaged {
    if (summary == null || summary!.incompleteTasks.isEmpty) return true;
    return summary!.incompleteTasks.every((t) => stagedActions.containsKey(t.id));
  }

  int get stagedCount => stagedActions.length;
  int get remainingToStage => (summary?.incompleteTasks.length ?? 0) - stagedCount;

  ReviewState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    ReviewSummaryModel? summary,
    Map<String, RescheduleItemModel>? stagedActions,
    String? errorMessage,
    bool? isCelebrationVisible,
    bool clearError = false,
  }) {
    return ReviewState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      summary: summary ?? this.summary,
      stagedActions: stagedActions ?? this.stagedActions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCelebrationVisible: isCelebrationVisible ?? this.isCelebrationVisible,
    );
  }
}

final reviewControllerProvider =
    StateNotifierProvider<ReviewController, ReviewState>((ref) {
  final reviewRepo = ref.watch(reviewRepositoryProvider);
  final tasksNotifier = ref.read(tasksControllerProvider.notifier);
  final plannerNotifier = ref.read(plannerControllerProvider.notifier);
  return ReviewController(reviewRepo, tasksNotifier, plannerNotifier);
});

class ReviewController extends StateNotifier<ReviewState> {
  final ReviewRepository _reviewRepository;
  final TasksController _tasksController;
  final PlannerController _plannerController;

  ReviewController(
    this._reviewRepository,
    this._tasksController,
    this._plannerController,
  ) : super(const ReviewState()) {
    loadReview();
  }

  Future<void> loadReview({String? date}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final summary = await _reviewRepository.getDailyReview(date: date);
      state = state.copyWith(
        isLoading: false,
        summary: summary,
        stagedActions: {},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractError(e, 'Failed to load daily review.'),
      );
    }
  }

  void stageAction(String taskId, RescheduleAction action, {DateTime? customDeadline}) {
    final updated = Map<String, RescheduleItemModel>.from(state.stagedActions);
    updated[taskId] = RescheduleItemModel(
      taskId: taskId,
      action: action,
      newDeadline: customDeadline,
    );
    state = state.copyWith(stagedActions: updated);
  }

  void unstageAction(String taskId) {
    final updated = Map<String, RescheduleItemModel>.from(state.stagedActions);
    updated.remove(taskId);
    state = state.copyWith(stagedActions: updated);
  }

  Future<bool> applyBatchReschedule() async {
    if (state.stagedActions.isEmpty) {
      state = state.copyWith(isCelebrationVisible: true);
      return true;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final items = state.stagedActions.values.toList();
      await _reviewRepository.batchReschedule(items);
      await _tasksController.refreshTasks();
      await _plannerController.loadData();
      await loadReview();

      state = state.copyWith(
        isSubmitting: false,
        isCelebrationVisible: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _extractError(e, 'Failed to apply rescheduling.'),
      );
      return false;
    }
  }

  void dismissCelebration() {
    state = state.copyWith(isCelebrationVisible: false);
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
