import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/analytics/data/analytics_repository.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

class AnalyticsState {
  final bool isLoading;
  final String? errorMessage;
  final AnalyticsOverviewModel? overview;
  final WeeklyAnalyticsModel? weekly;
  final AnalyticsBreakdownModel? breakdown;
  final AnalyticsHeatmapModel? heatmap;

  const AnalyticsState({
    this.isLoading = false,
    this.errorMessage,
    this.overview,
    this.weekly,
    this.breakdown,
    this.heatmap,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    String? errorMessage,
    AnalyticsOverviewModel? overview,
    WeeklyAnalyticsModel? weekly,
    AnalyticsBreakdownModel? breakdown,
    AnalyticsHeatmapModel? heatmap,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      overview: overview ?? this.overview,
      weekly: weekly ?? this.weekly,
      breakdown: breakdown ?? this.breakdown,
      heatmap: heatmap ?? this.heatmap,
    );
  }
}

final analyticsControllerProvider =
    StateNotifierProvider<AnalyticsController, AnalyticsState>((ref) {
  final repository = ref.watch(analyticsRepositoryProvider);
  return AnalyticsController(repository);
});

class AnalyticsController extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsController(this._repository) : super(const AnalyticsState()) {
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final results = await Future.wait([
        _repository.fetchOverview(days: 30),
        _repository.fetchWeekly(days: 7),
        _repository.fetchBreakdown(days: 30),
        _repository.fetchHeatmap(days: 30),
      ]);

      state = state.copyWith(
        isLoading: false,
        overview: results[0] as AnalyticsOverviewModel,
        weekly: results[1] as WeeklyAnalyticsModel,
        breakdown: results[2] as AnalyticsBreakdownModel,
        heatmap: results[3] as AnalyticsHeatmapModel,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load analytics: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() => loadAnalytics();
}
