import 'package:intl/intl.dart';

enum ReminderPreset {
  none(label: 'None', offset: null),
  fifteenMinutes(label: '15m before', offset: Duration(minutes: 15)),
  thirtyMinutes(label: '30m before', offset: Duration(minutes: 30)),
  oneHour(label: '1h before', offset: Duration(hours: 1)),
  threeHours(label: '3h before', offset: Duration(hours: 3)),
  oneDay(label: '1d before', offset: Duration(days: 1)),
  custom(label: 'Custom', offset: null);

  final String label;
  final Duration? offset;

  const ReminderPreset({required this.label, this.offset});

  DateTime? calculateRemindAt(DateTime? deadline) {
    if (deadline == null || offset == null) return null;
    return deadline.subtract(offset!);
  }
}

class ReminderModel {
  final String id;
  final String taskId;
  final int? notificationId;
  final DateTime remindAt;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReminderModel({
    required this.id,
    required this.taskId,
    this.notificationId,
    required this.remindAt,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get isScheduled => status == 'SCHEDULED';

  String get formattedRemindAt {
    final localTime = remindAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(localTime.year, localTime.month, localTime.day);
    final diff = reminderDay.difference(today).inDays;

    final timeStr = DateFormat('h:mm a').format(localTime);
    if (diff == 0) {
      return 'Today • $timeStr';
    } else if (diff == 1) {
      return 'Tomorrow • $timeStr';
    } else {
      return '${DateFormat('MMM d').format(localTime)} • $timeStr';
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

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      notificationId: json['notification_id'] as int?,
      remindAt: parseUtcDateTime(json['remind_at']) ?? DateTime.now(),
      status: (json['status'] ?? 'SCHEDULED') as String,
      createdAt: parseUtcDateTime(json['created_at']),
      updatedAt: parseUtcDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      if (notificationId != null) 'notification_id': notificationId,
      'remind_at': remindAt.toUtc().toIso8601String(),
      'status': status,
    };
  }

  ReminderModel copyWith({
    String? id,
    String? taskId,
    int? notificationId,
    DateTime? remindAt,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      notificationId: notificationId ?? this.notificationId,
      remindAt: remindAt ?? this.remindAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
