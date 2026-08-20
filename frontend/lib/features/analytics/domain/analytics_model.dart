import 'package:flutter/material.dart';

class StreakInfoModel {
  final int currentStreak;
  final int longestStreak;

  const StreakInfoModel({
    required this.currentStreak,
    required this.longestStreak,
  });

  factory StreakInfoModel.fromJson(Map<String, dynamic> json) {
    return StreakInfoModel(
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class PersonalRecordsModel {
  final int bestDayTasks;
  final int bestDayFocusMinutes;
  final int longestStreak;

  const PersonalRecordsModel({
    required this.bestDayTasks,
    required this.bestDayFocusMinutes,
    required this.longestStreak,
  });

  factory PersonalRecordsModel.fromJson(Map<String, dynamic> json) {
    return PersonalRecordsModel(
      bestDayTasks: (json['best_day_tasks'] as num?)?.toInt() ?? 0,
      bestDayFocusMinutes: (json['best_day_focus_minutes'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class GoalAnalyticsModel {
  final int activeGoals;
  final int completedGoals;
  final int totalGoals;
  final double goalCompletionRate;
  final int completedMilestones;
  final int totalMilestones;
  final double milestoneCompletionRate;

  const GoalAnalyticsModel({
    required this.activeGoals,
    required this.completedGoals,
    required this.totalGoals,
    required this.goalCompletionRate,
    required this.completedMilestones,
    required this.totalMilestones,
    required this.milestoneCompletionRate,
  });

  factory GoalAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return GoalAnalyticsModel(
      activeGoals: (json['active_goals'] as num?)?.toInt() ?? 0,
      completedGoals: (json['completed_goals'] as num?)?.toInt() ?? 0,
      totalGoals: (json['total_goals'] as num?)?.toInt() ?? 0,
      goalCompletionRate: (json['goal_completion_rate'] as num?)?.toDouble() ?? 0.0,
      completedMilestones: (json['completed_milestones'] as num?)?.toInt() ?? 0,
      totalMilestones: (json['total_milestones'] as num?)?.toInt() ?? 0,
      milestoneCompletionRate: (json['milestone_completion_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FocusTimeModel {
  final int todayMinutes;
  final int weekMinutes;
  final int monthMinutes;

  const FocusTimeModel({
    required this.todayMinutes,
    required this.weekMinutes,
    required this.monthMinutes,
  });

  factory FocusTimeModel.fromJson(Map<String, dynamic> json) {
    return FocusTimeModel(
      todayMinutes: (json['today_minutes'] as num?)?.toInt() ?? 0,
      weekMinutes: (json['week_minutes'] as num?)?.toInt() ?? 0,
      monthMinutes: (json['month_minutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductivityInsightsModel {
  final String mostProductiveDay;
  final String mostProductiveWindow;
  final double mostProductiveWindowPercentage;

  const ProductivityInsightsModel({
    required this.mostProductiveDay,
    required this.mostProductiveWindow,
    required this.mostProductiveWindowPercentage,
  });

  factory ProductivityInsightsModel.fromJson(Map<String, dynamic> json) {
    return ProductivityInsightsModel(
      mostProductiveDay: json['most_productive_day'] as String? ?? 'N/A',
      mostProductiveWindow: json['most_productive_window'] as String? ?? 'N/A',
      mostProductiveWindowPercentage: (json['most_productive_window_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CompletionStatsModel {
  final int totalCompletedTasks;
  final int totalDueTasks;
  final double overallCompletionRate;
  final double onTimeCompletionRate;
  final double overdueCompletionRate;

  const CompletionStatsModel({
    required this.totalCompletedTasks,
    required this.totalDueTasks,
    required this.overallCompletionRate,
    required this.onTimeCompletionRate,
    required this.overdueCompletionRate,
  });

  factory CompletionStatsModel.fromJson(Map<String, dynamic> json) {
    return CompletionStatsModel(
      totalCompletedTasks: (json['total_completed_tasks'] as num?)?.toInt() ?? 0,
      totalDueTasks: (json['total_due_tasks'] as num?)?.toInt() ?? 0,
      overallCompletionRate: (json['overall_completion_rate'] as num?)?.toDouble() ?? 0.0,
      onTimeCompletionRate: (json['on_time_completion_rate'] as num?)?.toDouble() ?? 0.0,
      overdueCompletionRate: (json['overdue_completion_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AnalyticsOverviewModel {
  final StreakInfoModel streaks;
  final PersonalRecordsModel personalRecords;
  final GoalAnalyticsModel goalsSummary;
  final FocusTimeModel focusTime;
  final ProductivityInsightsModel productivityInsights;
  final CompletionStatsModel completionStats;

  const AnalyticsOverviewModel({
    required this.streaks,
    required this.personalRecords,
    required this.goalsSummary,
    required this.focusTime,
    required this.productivityInsights,
    required this.completionStats,
  });

  factory AnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverviewModel(
      streaks: StreakInfoModel.fromJson(json['streaks'] as Map<String, dynamic>? ?? {}),
      personalRecords: PersonalRecordsModel.fromJson(json['personal_records'] as Map<String, dynamic>? ?? {}),
      goalsSummary: GoalAnalyticsModel.fromJson(json['goals_summary'] as Map<String, dynamic>? ?? {}),
      focusTime: FocusTimeModel.fromJson(json['focus_time'] as Map<String, dynamic>? ?? {}),
      productivityInsights: ProductivityInsightsModel.fromJson(json['productivity_insights'] as Map<String, dynamic>? ?? {}),
      completionStats: CompletionStatsModel.fromJson(json['completion_stats'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class WeeklyDayModel {
  final String date;
  final String dayLabel;
  final int completedCount;
  final int totalDueCount;
  final double completionRate;
  final int completedMinutes;

  const WeeklyDayModel({
    required this.date,
    required this.dayLabel,
    required this.completedCount,
    required this.totalDueCount,
    required this.completionRate,
    required this.completedMinutes,
  });

  factory WeeklyDayModel.fromJson(Map<String, dynamic> json) {
    return WeeklyDayModel(
      date: json['date'] as String? ?? '',
      dayLabel: json['day_label'] as String? ?? '',
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      totalDueCount: (json['total_due_count'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      completedMinutes: (json['completed_minutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimeOfDayBreakdownModel {
  final int morning;
  final int afternoon;
  final int evening;
  final int night;

  const TimeOfDayBreakdownModel({
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.night,
  });

  factory TimeOfDayBreakdownModel.fromJson(Map<String, dynamic> json) {
    return TimeOfDayBreakdownModel(
      morning: (json['morning'] as num?)?.toInt() ?? 0,
      afternoon: (json['afternoon'] as num?)?.toInt() ?? 0,
      evening: (json['evening'] as num?)?.toInt() ?? 0,
      night: (json['night'] as num?)?.toInt() ?? 0,
    );
  }
}

class WeeklyAnalyticsModel {
  final List<WeeklyDayModel> days;
  final TimeOfDayBreakdownModel timeOfDayBreakdown;

  const WeeklyAnalyticsModel({
    required this.days,
    required this.timeOfDayBreakdown,
  });

  factory WeeklyAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return WeeklyAnalyticsModel(
      days: (json['days'] as List<dynamic>?)
              ?.map((e) => WeeklyDayModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeOfDayBreakdown: TimeOfDayBreakdownModel.fromJson(json['time_of_day_breakdown'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class CategoryBreakdownItemModel {
  final String? categoryId;
  final String name;
  final String colorHex;
  final int count;
  final double percentage;

  const CategoryBreakdownItemModel({
    this.categoryId,
    required this.name,
    required this.colorHex,
    required this.count,
    required this.percentage,
  });

  factory CategoryBreakdownItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItemModel(
      categoryId: json['category_id'] as String?,
      name: json['name'] as String? ?? 'Uncategorized',
      colorHex: json['color'] as String? ?? '#6366F1',
      count: (json['count'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class PriorityBreakdownModel {
  final int critical;
  final int high;
  final int medium;
  final int low;

  const PriorityBreakdownModel({
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
  });

  factory PriorityBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PriorityBreakdownModel(
      critical: (json['critical'] as num?)?.toInt() ?? 0,
      high: (json['high'] as num?)?.toInt() ?? 0,
      medium: (json['medium'] as num?)?.toInt() ?? 0,
      low: (json['low'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsBreakdownModel {
  final List<CategoryBreakdownItemModel> categories;
  final PriorityBreakdownModel priorities;

  const AnalyticsBreakdownModel({
    required this.categories,
    required this.priorities,
  });

  factory AnalyticsBreakdownModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsBreakdownModel(
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => CategoryBreakdownItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      priorities: PriorityBreakdownModel.fromJson(json['priorities'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class HeatmapDayModel {
  final String date;
  final int count;
  final int level;

  const HeatmapDayModel({
    required this.date,
    required this.count,
    required this.level,
  });

  factory HeatmapDayModel.fromJson(Map<String, dynamic> json) {
    return HeatmapDayModel(
      date: json['date'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsHeatmapModel {
  final List<HeatmapDayModel> heatmap;

  const AnalyticsHeatmapModel({required this.heatmap});

  factory AnalyticsHeatmapModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsHeatmapModel(
      heatmap: (json['heatmap'] as List<dynamic>?)
              ?.map((e) => HeatmapDayModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
