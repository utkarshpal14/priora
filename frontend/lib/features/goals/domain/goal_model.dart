import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend/features/tasks/domain/category_model.dart';
import 'package:frontend/features/tasks/domain/task_model.dart';

enum GoalStatus {
  inProgress('IN_PROGRESS', 'In Progress', Color(0xFF6366F1)),
  completed('COMPLETED', 'Completed', Color(0xFF10B981)),
  paused('PAUSED', 'Paused', Color(0xFFF59E0B)),
  archived('ARCHIVED', 'Archived', Color(0xFF94A3B8));

  final String apiValue;
  final String label;
  final Color color;

  const GoalStatus(this.apiValue, this.label, this.color);

  static GoalStatus fromString(String? value) {
    if (value == null) return GoalStatus.inProgress;
    for (final status in GoalStatus.values) {
      if (status.apiValue.toUpperCase() == value.toUpperCase()) {
        return status;
      }
    }
    return GoalStatus.inProgress;
  }
}

class GoalMilestoneModel {
  final String id;
  final String goalId;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final bool isCompleted;
  final int orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GoalMilestoneModel({
    required this.id,
    required this.goalId,
    required this.title,
    this.description,
    this.targetDate,
    this.isCompleted = false,
    this.orderIndex = 0,
    this.createdAt,
    this.updatedAt,
  });

  String? get formattedTargetDate {
    if (targetDate == null) return null;
    return DateFormat('MMM d, yyyy').format(targetDate!);
  }

  factory GoalMilestoneModel.fromJson(Map<String, dynamic> json) {
    return GoalMilestoneModel(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetDate: json['target_date'] != null
          ? DateTime.tryParse(json['target_date'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? TaskModel.parseUtcDateTime(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? TaskModel.parseUtcDateTime(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'target_date': targetDate != null ? DateFormat('yyyy-MM-dd').format(targetDate!) : null,
      'order_index': orderIndex,
    };
  }

  GoalMilestoneModel copyWith({
    String? id,
    String? goalId,
    String? title,
    String? description,
    DateTime? targetDate,
    bool? isCompleted,
    int? orderIndex,
  }) {
    return GoalMilestoneModel(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class GoalActivityItem {
  final String id;
  final String type; // "MILESTONE" or "TASK"
  final String title;
  final DateTime completedAt;
  final String? description;

  const GoalActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.completedAt,
    this.description,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(completedAt);
    if (diff.inDays > 30) return DateFormat('MMM d').format(completedAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  factory GoalActivityItem.fromJson(Map<String, dynamic> json) {
    return GoalActivityItem(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'TASK',
      title: json['title'] as String? ?? '',
      completedAt: json['completed_at'] != null
          ? TaskModel.parseUtcDateTime(json['completed_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      description: json['description'] as String?,
    );
  }
}

class GoalModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final String? categoryId;
  final CategoryModel? category;
  final GoalStatus status;
  final String color;
  final String icon;
  final double progressPercentage;
  final int milestonesCount;
  final int completedMilestonesCount;
  final int tasksCount;
  final int completedTasksCount;
  final List<GoalMilestoneModel> milestones;
  final List<TaskModel> tasks;
  final List<GoalActivityItem> recentActivity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.targetDate,
    this.categoryId,
    this.category,
    this.status = GoalStatus.inProgress,
    this.color = '#6366F1',
    this.icon = 'flag_rounded',
    this.progressPercentage = 0.0,
    this.milestonesCount = 0,
    this.completedMilestonesCount = 0,
    this.tasksCount = 0,
    this.completedTasksCount = 0,
    this.milestones = const [],
    this.tasks = const [],
    this.recentActivity = const [],
    this.createdAt,
    this.updatedAt,
  });

  String? get formattedTargetDate {
    if (targetDate == null) return null;
    return DateFormat('MMM d, yyyy').format(targetDate!);
  }

  int? get daysRemaining {
    if (targetDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate!.year, targetDate!.month, targetDate!.day);
    return target.difference(today).inDays;
  }

  Color get displayColor {
    try {
      final hex = color.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF6366F1);
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'] as List<dynamic>? ?? [];
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    final rawActivity = json['recent_activity'] as List<dynamic>? ?? [];

    return GoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetDate: json['target_date'] != null
          ? DateTime.tryParse(json['target_date'] as String)
          : null,
      categoryId: json['category_id'] as String?,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      status: GoalStatus.fromString(json['status'] as String?),
      color: json['color'] as String? ?? '#6366F1',
      icon: json['icon'] as String? ?? 'flag_rounded',
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      milestonesCount: (json['milestones_count'] as num?)?.toInt() ?? 0,
      completedMilestonesCount: (json['completed_milestones_count'] as num?)?.toInt() ?? 0,
      tasksCount: (json['tasks_count'] as num?)?.toInt() ?? 0,
      completedTasksCount: (json['completed_tasks_count'] as num?)?.toInt() ?? 0,
      milestones: rawMilestones
          .map((m) => GoalMilestoneModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      tasks: rawTasks
          .map((t) => TaskModel.fromJson(t as Map<String, dynamic>))
          .toList(),
      recentActivity: rawActivity
          .map((a) => GoalActivityItem.fromJson(a as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? TaskModel.parseUtcDateTime(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? TaskModel.parseUtcDateTime(json['updated_at'] as String)
          : null,
    );
  }

  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? targetDate,
    String? categoryId,
    CategoryModel? category,
    GoalStatus? status,
    String? color,
    String? icon,
    double? progressPercentage,
    int? milestonesCount,
    int? completedMilestonesCount,
    int? tasksCount,
    int? completedTasksCount,
    List<GoalMilestoneModel>? milestones,
    List<TaskModel>? tasks,
    List<GoalActivityItem>? recentActivity,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      status: status ?? this.status,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      milestonesCount: milestonesCount ?? this.milestonesCount,
      completedMilestonesCount: completedMilestonesCount ?? this.completedMilestonesCount,
      tasksCount: tasksCount ?? this.tasksCount,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      milestones: milestones ?? this.milestones,
      tasks: tasks ?? this.tasks,
      recentActivity: recentActivity ?? this.recentActivity,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
