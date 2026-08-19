import 'package:intl/intl.dart';

import 'package:frontend/features/tasks/domain/task_model.dart';

class TaskSessionModel {
  final String id;
  final String taskId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final int durationMinutes;
  final String formattedTimeRange;
  final bool hasConflict;
  final List<String> conflictingWith;
  final TaskModel? task;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TaskSessionModel({
    required this.id,
    required this.taskId,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.durationMinutes,
    required this.formattedTimeRange,
    this.hasConflict = false,
    this.conflictingWith = const [],
    this.task,
    this.createdAt,
    this.updatedAt,
  });

  String get formattedDuration {
    if (durationMinutes < 60) return '${durationMinutes}m';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  factory TaskSessionModel.fromJson(Map<String, dynamic> json) {
    final rawConflicting = json['conflicting_with'] as List<dynamic>? ?? [];
    return TaskSessionModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      scheduledStart: TaskModel.parseUtcDateTime(json['scheduled_start'] as String) ?? DateTime.now(),
      scheduledEnd: TaskModel.parseUtcDateTime(json['scheduled_end'] as String) ?? DateTime.now(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      formattedTimeRange: json['formatted_time_range'] as String? ?? '',
      hasConflict: json['has_conflict'] as bool? ?? false,
      conflictingWith: rawConflicting.map((e) => e.toString()).toList(),
      task: json['task'] != null ? TaskModel.fromJson(json['task'] as Map<String, dynamic>) : null,
      createdAt: json['created_at'] != null ? TaskModel.parseUtcDateTime(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? TaskModel.parseUtcDateTime(json['updated_at'] as String) : null,
    );
  }
}

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

  String get formattedWorkloadDuration {
    if (totalEstimatedMinutes <= 0) return '0m';
    final h = totalEstimatedMinutes ~/ 60;
    final m = totalEstimatedMinutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String get formattedTotalDuration => formattedWorkloadDuration;

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
  final List<TaskSessionModel> timeBlocks;
  final List<TaskModel> unscheduledTasks;
  final List<TimelineBucketModel> timeline;

  const DailyPlanModel({
    required this.date,
    required this.summary,
    this.overdueTasks = const [],
    this.focusTasks = const [],
    this.timeBlocks = const [],
    this.unscheduledTasks = const [],
    this.timeline = const [],
  });

  factory DailyPlanModel.fromJson(Map<String, dynamic> json) {
    final rawOverdue = json['overdue_tasks'] as List<dynamic>? ?? [];
    final rawFocus = json['focus_tasks'] as List<dynamic>? ?? [];
    final rawBlocks = json['time_blocks'] as List<dynamic>? ?? [];
    final rawUnscheduled = json['unscheduled_tasks'] as List<dynamic>? ?? [];
    final rawTimeline = json['timeline'] as List<dynamic>? ?? [];

    return DailyPlanModel(
      date: (json['date'] ?? '') as String,
      summary: json['summary'] != null
          ? DayPlanSummaryModel.fromJson(json['summary'] as Map<String, dynamic>)
          : const DayPlanSummaryModel(),
      overdueTasks: rawOverdue.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList(),
      focusTasks: rawFocus.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList(),
      timeBlocks: rawBlocks.map((b) => TaskSessionModel.fromJson(b as Map<String, dynamic>)).toList(),
      unscheduledTasks: rawUnscheduled.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList(),
      timeline: rawTimeline.map((b) => TimelineBucketModel.fromJson(b as Map<String, dynamic>)).toList(),
    );
  }
}

class WeeklyPlanDayModel {
  final String date;
  final String dayName;
  final int taskCount;
  final int dueCount;
  final int completedCount;
  final int overdueCount;
  final bool hasCritical;

  const WeeklyPlanDayModel({
    required this.date,
    required this.dayName,
    this.taskCount = 0,
    this.dueCount = 0,
    this.completedCount = 0,
    this.overdueCount = 0,
    this.hasCritical = false,
  });

  factory WeeklyPlanDayModel.fromJson(Map<String, dynamic> json) {
    return WeeklyPlanDayModel(
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
  final List<WeeklyPlanDayModel> days;
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
      days: rawDays.map((d) => WeeklyPlanDayModel.fromJson(d as Map<String, dynamic>)).toList(),
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
    );
  }
}

typedef WeeklyDayModel = WeeklyPlanDayModel;
