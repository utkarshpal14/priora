import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/shared/widgets/app_empty_view.dart';
import 'package:frontend/shared/widgets/app_error_view.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(analyticsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics & Insights',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : AppColors.textSecondary),
            onPressed: () => ref.read(analyticsControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(analyticsControllerProvider.notifier).refresh(),
        color: theme.colorScheme.secondary,
        backgroundColor: theme.colorScheme.surface,
        child: state.isLoading
            ? Center(
                child: CircularProgressIndicator(color: theme.colorScheme.secondary),
              )
            : state.errorMessage != null
                ? AppErrorView(
                    message: state.errorMessage!,
                    onRetry: () => ref.read(analyticsControllerProvider.notifier).refresh(),
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
