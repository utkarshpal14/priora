import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/analytics/data/analytics_api.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final api = ref.watch(analyticsApiProvider);
  return AnalyticsRepository(api);
});

class AnalyticsRepository {
  final AnalyticsApi _api;

  AnalyticsRepository(this._api);

  Future<AnalyticsOverviewModel> fetchOverview({int days = 30}) => _api.getOverview(days: days);

  Future<WeeklyAnalyticsModel> fetchWeekly({int days = 7}) => _api.getWeekly(days: days);

  Future<AnalyticsBreakdownModel> fetchBreakdown({int days = 30}) => _api.getBreakdown(days: days);

  Future<AnalyticsHeatmapModel> fetchHeatmap({int days = 30}) => _api.getHeatmap(days: days);
}
