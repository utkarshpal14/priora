import 'package:frontend/features/tasks/domain/task_model.dart';

class DayPlanSummaryModel {
  final int total;
  final int completed;
  final int pending;
  final int overdueCount;
  final double completionPercentage;
  final int totalEstimatedMinutes;

  const DayPlanSummaryModel({
    this.total = 0,
    this.completed = 0,
    this.pending = 0,
    this.overdueCount = 0,
    this.completionPercentage = 0.0,
    this.totalEstimatedMinutes = 0,
  });

  String get formattedTotalDuration {
    if (totalEstimatedMinutes <= 0) return '0m';
    final h = totalEstimatedMinutes ~/ 60;
    final m = totalEstimatedMinutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  factory DayPlanSummaryModel.fromJson(Map<String, dynamic> json) {
    return DayPlanSummaryModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      overdueCount: (json['overdue_count'] as num?)?.toInt() ?? 0,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      totalEstimatedMinutes: (json['total_estimated_minutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimelineBucketModel {
  final String name;
  final String timeRange;
  final List<TaskModel> tasks;

  const TimelineBucketModel({
    required this.name,
    required this.timeRange,
    this.tasks = const [],
  });

  factory TimelineBucketModel.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    return TimelineBucketModel(
      name: (json['name'] ?? '') as String,
      timeRange: (json['time_range'] ?? '') as String,
      tasks: rawTasks.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}

class DailyPlanModel {
  final String date;
  final DayPlanSummaryModel summary;
  final List<TaskModel> overdueTasks;
  final List<TaskModel> focusTasks;
  final List<TimelineBucketModel> timeline;

  const DailyPlanModel({
    required this.date,
    this.summary = const DayPlanSummaryModel(),
    this.overdueTasks = const [],
    this.focusTasks = const [],
    this.timeline = const [],
  });

  factory DailyPlanModel.fromJson(Map<String, dynamic> json) {
    final rawOverdue = json['overdue_tasks'] as List<dynamic>? ?? [];
    final rawFocus = json['focus_tasks'] as List<dynamic>? ?? [];
    final rawTimeline = json['timeline'] as List<dynamic>? ?? [];

    return DailyPlanModel(
      date: (json['date'] ?? '') as String,
      summary: json['summary'] != null
          ? DayPlanSummaryModel.fromJson(json['summary'] as Map<String, dynamic>)
          : const DayPlanSummaryModel(),
      overdueTasks: rawOverdue.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList(),
      focusTasks: rawFocus.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList(),
      timeline: rawTimeline.map((b) => TimelineBucketModel.fromJson(b as Map<String, dynamic>)).toList(),
    );
  }
}

class WeeklyDayModel {
  final String date;
  final String dayName;
  final int taskCount;
  final int dueCount;
  final int completedCount;
  final int overdueCount;
  final bool hasCritical;

  const WeeklyDayModel({
    required this.date,
    required this.dayName,
    this.taskCount = 0,
    this.dueCount = 0,
    this.completedCount = 0,
    this.overdueCount = 0,
    this.hasCritical = false,
  });

  factory WeeklyDayModel.fromJson(Map<String, dynamic> json) {
    return WeeklyDayModel(
      date: (json['date'] ?? '') as String,
      dayName: (json['day_name'] ?? '') as String,
      taskCount: (json['task_count'] as num?)?.toInt() ?? 0,
      dueCount: (json['due_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      overdueCount: (json['overdue_count'] as num?)?.toInt() ?? 0,
      hasCritical: (json['has_critical'] as bool?) ?? false,
    );
  }
}

class WeeklyPlanModel {
  final String startDate;
  final String endDate;
  final List<WeeklyDayModel> days;
  final int totalTasks;
  final int completedTasks;

  const WeeklyPlanModel({
    required this.startDate,
    required this.endDate,
    this.days = const [],
    this.totalTasks = 0,
    this.completedTasks = 0,
  });

  factory WeeklyPlanModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? [];
    return WeeklyPlanModel(
      startDate: (json['start_date'] ?? '') as String,
      endDate: (json['end_date'] ?? '') as String,
      days: rawDays.map((d) => WeeklyDayModel.fromJson(d as Map<String, dynamic>)).toList(),
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
    );
  }
}
