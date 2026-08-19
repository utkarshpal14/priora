import 'package:frontend/features/tasks/domain/task_model.dart';

enum RescheduleAction {
  moveTomorrow('MOVE_TOMORROW'),
  moveNextWeek('MOVE_NEXT_WEEK'),
  schedule('SCHEDULE'),
  complete('COMPLETE'),
  cancel('CANCEL');

  final String apiValue;
  const RescheduleAction(this.apiValue);
}

class RescheduleItemModel {
  final String taskId;
  final RescheduleAction action;
  final DateTime? newDeadline;

  const RescheduleItemModel({
    required this.taskId,
    required this.action,
    this.newDeadline,
  });

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'action': action.apiValue,
      'new_deadline': newDeadline?.toUtc().toIso8601String(),
    };
  }
}

class ReviewSummaryModel {
  final String date;
  final List<TaskModel> completedTasks;
  final List<TaskModel> incompleteTasks;
  final int completedCount;
  final int incompleteCount;
  final int overdueCount;
  final double completionRate;
  final int totalCompletedMinutes;

  const ReviewSummaryModel({
    required this.date,
    this.completedTasks = const [],
    this.incompleteTasks = const [],
    this.completedCount = 0,
    this.incompleteCount = 0,
    this.overdueCount = 0,
    this.completionRate = 0.0,
    this.totalCompletedMinutes = 0,
  });

  String get formattedCompletedDuration {
    if (totalCompletedMinutes <= 0) return '0m';
    final h = totalCompletedMinutes ~/ 60;
    final m = totalCompletedMinutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  factory ReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawCompleted = json['completed_tasks'] as List<dynamic>? ?? [];
    final rawIncomplete = json['incomplete_tasks'] as List<dynamic>? ?? [];

    return ReviewSummaryModel(
      date: (json['date'] ?? '') as String,
      completedTasks: rawCompleted.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList(),
      incompleteTasks: rawIncomplete.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList(),
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      incompleteCount: (json['incomplete_count'] as num?)?.toInt() ?? 0,
      overdueCount: (json['overdue_count'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      totalCompletedMinutes: (json['total_completed_minutes'] as num?)?.toInt() ?? 0,
    );
  }
}
