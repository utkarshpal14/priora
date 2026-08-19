import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final Map<int, Timer> _activeTimers = {};

  Future<void> initialize() async {
    debugPrint('[LocalNotificationService] Initialized local notification engine.');
  }

  Future<int> scheduleNotification({
    int? notificationId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final id = notificationId ?? (DateTime.now().millisecondsSinceEpoch.remainder(100000));
    final now = DateTime.now();
    final delay = scheduledDate.difference(now);

    debugPrint('[LocalNotificationService] Scheduled notification #$id for $scheduledDate ($title)');

    if (delay.isNegative) {
      debugPrint('[LocalNotificationService] Notification #$id timestamp in the past, skipping timer.');
      return id;
    }

    _activeTimers[id]?.cancel();

    _activeTimers[id] = Timer(delay, () {
      debugPrint('[LocalNotificationService] ⏰ ALARM FIRED (#$id): $title - $body');
      _activeTimers.remove(id);
    });

    return id;
  }

  Future<void> cancelNotification(int notificationId) async {
    _activeTimers[notificationId]?.cancel();
    _activeTimers.remove(notificationId);
    debugPrint('[LocalNotificationService] Cancelled notification #$notificationId');
  }

  Future<void> cancelTaskNotifications(List<int> notificationIds) async {
    for (final id in notificationIds) {
      await cancelNotification(id);
    }
  }

  Future<void> cancelAll() async {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    debugPrint('[LocalNotificationService] Cancelled all local notifications.');
  }
}

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});
