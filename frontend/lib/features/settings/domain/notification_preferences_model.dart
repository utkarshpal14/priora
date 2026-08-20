class NotificationPreferencesModel {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool deadlineReminders;
  final bool sessionReminders;
  final bool reviewReminders;
  final bool goalAlerts;

  const NotificationPreferencesModel({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.deadlineReminders = true,
    this.sessionReminders = true,
    this.reviewReminders = true,
    this.goalAlerts = true,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      notificationsEnabled: json['notifications_enabled'] ?? true,
      soundEnabled: json['sound_enabled'] ?? true,
      deadlineReminders: json['deadline_reminders'] ?? true,
      sessionReminders: json['session_reminders'] ?? true,
      reviewReminders: json['review_reminders'] ?? true,
      goalAlerts: json['goal_alerts'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications_enabled': notificationsEnabled,
      'sound_enabled': soundEnabled,
      'deadline_reminders': deadlineReminders,
      'session_reminders': sessionReminders,
      'review_reminders': reviewReminders,
      'goal_alerts': goalAlerts,
    };
  }

  NotificationPreferencesModel copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? deadlineReminders,
    bool? sessionReminders,
    bool? reviewReminders,
    bool? goalAlerts,
  }) {
    return NotificationPreferencesModel(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      deadlineReminders: deadlineReminders ?? this.deadlineReminders,
      sessionReminders: sessionReminders ?? this.sessionReminders,
      reviewReminders: reviewReminders ?? this.reviewReminders,
      goalAlerts: goalAlerts ?? this.goalAlerts,
    );
  }
}
