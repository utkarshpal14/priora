import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/analytics/domain/analytics_model.dart';

final analyticsApiProvider = Provider<AnalyticsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return AnalyticsApi(dio);
});

class AnalyticsApi {
  final Dio _dio;

  AnalyticsApi(this._dio);

  int get _localTzOffsetMinutes => DateTime.now().timeZoneOffset.inMinutes;

  Future<AnalyticsOverviewModel> getOverview({int days = 30}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsOverview,
      queryParameters: {
        'days': days,
        'tz_offset': _localTzOffsetMinutes,
      },
    );
    return AnalyticsOverviewModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<WeeklyAnalyticsModel> getWeekly({int days = 7}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsWeekly,
      queryParameters: {
        'days': days,
        'tz_offset': _localTzOffsetMinutes,
      },
    );
    return WeeklyAnalyticsModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AnalyticsBreakdownModel> getBreakdown({int days = 30}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsBreakdown,
      queryParameters: {
        'days': days,
        'tz_offset': _localTzOffsetMinutes,
      },
    );
    return AnalyticsBreakdownModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AnalyticsHeatmapModel> getHeatmap({int days = 30}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsHeatmap,
      queryParameters: {
        'days': days,
        'tz_offset': _localTzOffsetMinutes,
      },
    );
    return AnalyticsHeatmapModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
