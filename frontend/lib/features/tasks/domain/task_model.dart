import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../reminders/domain/reminder_model.dart';
import 'category_model.dart';

enum TaskPriority {
  low('LOW', 'Low', Color(0xFF2D6A4F), Color(0xFFE8F5E9)),
  medium('MEDIUM', 'Medium', Color(0xFFD97706), Color(0xFFFEF3C7)),
  high('HIGH', 'High', Color(0xFFEA580C), Color(0xFFFFEDD5)),
  critical('CRITICAL', 'Critical', Color(0xFFDC2626), Color(0xFFFEE2E2));

  final String apiValue;
  final String label;
  final Color color;
  final Color backgroundColor;

  const TaskPriority(this.apiValue, this.label, this.color, this.backgroundColor);

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (p) => p.apiValue == value.toUpperCase(),
      orElse: () => TaskPriority.medium,
    );
  }
}

enum TaskStatus {
  pending('PENDING', 'Pending'),
  inProgress('IN_PROGRESS', 'In Progress'),
  completed('COMPLETED', 'Completed'),
  cancelled('CANCELLED', 'Cancelled');

  final String apiValue;
  final String label;

  const TaskStatus(this.apiValue, this.label);

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (s) => s.apiValue == value.toUpperCase(),
      orElse: () => TaskStatus.pending,
    );
  }
}

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final String? categoryId;
  final CategoryModel? category;
  final String? goalId;
  final String? milestoneId;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? deadline;
  final int? estimatedMinutes;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ReminderModel> reminders;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.categoryId,
    this.category,
    this.goalId,
    this.milestoneId,
    this.scheduledStart,
    this.scheduledEnd,
    this.deadline,
    this.estimatedMinutes,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.reminders = const [],
  });

  bool get isCompleted => status == TaskStatus.completed;

  bool get hasActiveReminder => reminders.any((r) => r.isScheduled);

  String? get formattedTimeRange {
    if (scheduledStart == null || scheduledEnd == null) return null;
    final startStr = DateFormat('h:mm a').format(scheduledStart!.toLocal());
    final endStr = DateFormat('h:mm a').format(scheduledEnd!.toLocal());
    return '$startStr – $endStr';
  }

  String? get formattedDuration {
    if (scheduledStart != null && scheduledEnd != null) {
      final mins = scheduledEnd!.difference(scheduledStart!).inMinutes;
      if (mins < 60) return '${mins}m';
      final h = mins ~/ 60;
      final m = mins % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    if (estimatedMinutes == null) return null;
    if (estimatedMinutes! < 60) return '${estimatedMinutes}m';
    final h = estimatedMinutes! ~/ 60;
    final m = estimatedMinutes! % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  bool get isOverdue {
    if (isCompleted || status == TaskStatus.cancelled) return false;
    if (deadline == null) return false;
    return deadline!.toUtc().isBefore(DateTime.now().toUtc());
  }

  bool get isDueToday {
    if (isCompleted || status == TaskStatus.cancelled) return false;
    if (deadline == null) return false;
    final now = DateTime.now();
    final localDeadline = deadline!.toLocal();
    return localDeadline.year == now.year &&
        localDeadline.month == now.month &&
        localDeadline.day == now.day;
  }

  bool get isDueTomorrow {
    if (isCompleted || status == TaskStatus.cancelled) return false;
    if (deadline == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final localDeadline = deadline!.toLocal();
    return localDeadline.year == tomorrow.year &&
        localDeadline.month == tomorrow.month &&
        localDeadline.day == tomorrow.day;
  }

  String get formattedDeadline {
    if (deadline == null) return 'No deadline';
    final now = DateTime.now();
    final localDeadline = deadline!.toLocal();
    final todayStart = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(localDeadline.year, localDeadline.month, localDeadline.day);
    final dayDiff = deadlineDay.difference(todayStart).inDays;

    if (isOverdue) {
      if (dayDiff == 0) {
        return 'Overdue (Today • ${DateFormat('h:mm a').format(localDeadline)})';
      } else if (dayDiff == -1) {
        return 'Overdue (Yesterday • ${DateFormat('h:mm a').format(localDeadline)})';
      } else {
        return 'Overdue (${DateFormat('MMM d • h:mm a').format(localDeadline)})';
      }
    } else if (dayDiff == 0) {
      return 'Due Today • ${DateFormat('h:mm a').format(localDeadline)}';
    } else if (dayDiff == 1) {
      return 'Due Tomorrow • ${DateFormat('h:mm a').format(localDeadline)}';
    } else {
      return DateFormat('MMM d • h:mm a').format(localDeadline);
    }
  }

  static DateTime? parseUtcDateTime(dynamic value) {
    if (value == null) return null;
    String str = value.toString().trim();
    if (str.isEmpty) return null;
    str = str.replaceFirst(' ', 'T');
    DateTime dt;
    if (str.endsWith('Z') || RegExp(r'[+-]\d{2}(:?\d{2})?$').hasMatch(str)) {
      dt = DateTime.parse(str);
    } else {
      dt = DateTime.parse('${str}Z');
    }
    return dt.toLocal();
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawReminders = json['reminders'] as List<dynamic>?;
    return TaskModel(
      id: json['id'] as String,
      userId: (json['user_id'] ?? '') as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriority.fromString((json['priority'] ?? 'MEDIUM') as String),
      status: TaskStatus.fromString((json['status'] ?? 'PENDING') as String),
      categoryId: json['category_id'] as String?,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      goalId: json['goal_id'] as String?,
      milestoneId: json['milestone_id'] as String?,
      scheduledStart: parseUtcDateTime(json['scheduled_start']),
      scheduledEnd: parseUtcDateTime(json['scheduled_end']),
      deadline: parseUtcDateTime(json['deadline']),
      estimatedMinutes: json['estimated_minutes'] as int?,
      completedAt: parseUtcDateTime(json['completed_at']),
      createdAt: parseUtcDateTime(json['created_at']),
      updatedAt: parseUtcDateTime(json['updated_at']),
      reminders: rawReminders != null
          ? rawReminders.map((r) => ReminderModel.fromJson(r as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'priority': priority.apiValue,
      'status': status.apiValue,
      'category_id': categoryId,
      'goal_id': goalId,
      'milestone_id': milestoneId,
      'scheduled_start': scheduledStart?.toUtc().toIso8601String(),
      'scheduled_end': scheduledEnd?.toUtc().toIso8601String(),
      'deadline': deadline?.toUtc().toIso8601String(),
      'estimated_minutes': estimatedMinutes,
    };
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    String? categoryId,
    CategoryModel? category,
    String? goalId,
    String? milestoneId,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    DateTime? deadline,
    int? estimatedMinutes,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ReminderModel>? reminders,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      goalId: goalId ?? this.goalId,
      milestoneId: milestoneId ?? this.milestoneId,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      deadline: deadline ?? this.deadline,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminders: reminders ?? this.reminders,
    );
  }
}
