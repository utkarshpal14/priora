import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/analytics/presentation/controllers/analytics_controller.dart';
import 'package:frontend/features/analytics/presentation/widgets/activity_heatmap_grid_widget.dart';
import 'package:frontend/features/analytics/presentation/widgets/category_breakdown_widget.dart';
import 'package:frontend/features/analytics/presentation/widgets/focus_time_summary_card_widget.dart';
import 'package:frontend/features/analytics/presentation/widgets/goal_analytics_card_widget.dart';
import 'package:frontend/features/analytics/presentation/widgets/personal_records_card_widget.dart';
import 'package:frontend/features/analytics/presentation/widgets/productivity_insights_widget.dart';
import 'package:frontend/features/analytics/presentation/widgets/streak_card_widget.dart';
import 'package:frontend/features/analytics/presentation/widgets/weekly_velocity_chart_widget.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Analytics & Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(analyticsControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(analyticsControllerProvider.notifier).refresh(),
        color: const Color(0xFF6366F1),
        backgroundColor: const Color(0xFF1E293B),
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              )
            : state.errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (state.overview != null) ...[
                        StreakCardWidget(streaks: state.overview!.streaks),
                        const SizedBox(height: 16),
                        PersonalRecordsCardWidget(records: state.overview!.personalRecords),
                        const SizedBox(height: 16),
                        GoalAnalyticsCardWidget(goals: state.overview!.goalsSummary),
                        const SizedBox(height: 16),
                        FocusTimeSummaryCardWidget(focusTime: state.overview!.focusTime),
                        const SizedBox(height: 16),
                      ],
                      if (state.weekly != null) ...[
                        WeeklyVelocityChartWidget(weekly: state.weekly!),
                        const SizedBox(height: 16),
                      ],
                      if (state.overview != null && state.weekly != null) ...[
                        ProductivityInsightsWidget(
                          insights: state.overview!.productivityInsights,
                          timeOfDay: state.weekly!.timeOfDayBreakdown,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (state.breakdown != null) ...[
                        CategoryBreakdownWidget(breakdown: state.breakdown!),
                        const SizedBox(height: 16),
                      ],
                      if (state.heatmap != null) ...[
                        ActivityHeatmapGridWidget(heatmap: state.heatmap!),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
      ),
    );
  }
}
