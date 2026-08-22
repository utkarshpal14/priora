import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('[LocalNotificationService] Background notification tapped: ${notificationResponse.payload}');
}

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  static const MethodChannel _systemSettingsChannel = MethodChannel('com.example.frontend/system_settings');

  static const String _channelId = 'priora_reminders_v5';
  static const String _channelName = 'Reminders & Task Alerts';
  static const String _channelDesc = 'High priority notifications with vibration and floating heads-up banner alerts.';

  /// Initialize local notification engine, channels, and timezone data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        final locName = _findDeviceLocationName();
        tz.setLocalLocation(tz.getLocation(locName));
      } catch (_) {}

      const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInitSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
        macOS: darwinInitSettings,
      );

      final initSuccess = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[LocalNotificationService] Notification tapped: ${response.payload}');
        },
      );
      debugPrint('[LocalNotificationService] _notificationsPlugin.initialize result: $initSuccess');

      // Create High Importance Notification Channel on Android
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        try {
          await androidImplementation.deleteNotificationChannel('priora_reminders');
        } catch (_) {}

        const androidChannel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidImplementation.createNotificationChannel(androidChannel);
        debugPrint('[LocalNotificationService] Created notification channel $_channelId (Importance.max)');
      }

      _isInitialized = true;
      debugPrint('[LocalNotificationService] Successfully initialized native notification engine.');
    } catch (e, stack) {
      debugPrint('[LocalNotificationService] Initialization error: $e\n$stack');
    }
  }

  /// Request runtime notification permissions (Fixes BUG-008)
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        final exactGranted = await androidImplementation.requestExactAlarmsPermission();
        debugPrint('[LocalNotificationService] Android notification permission result: $granted | exactAlarms: $exactGranted');
        if (exactGranted == false) {
          debugPrint('[LocalNotificationService] Exact alarms permission missing. Opening native Alarms & Reminders system settings...');
          await openExactAlarmSettings();
        }

        // Check and trigger native Android System Dialog for Battery Optimization & App Hibernation
        final isIgnored = await isBatteryOptimizationIgnored();
        if (!isIgnored) {
          debugPrint('[LocalNotificationService] Battery optimization active. Prompting native Android system dialog...');
          await openBatteryOptimizationPrompt();
        }

        return granted ?? false;
      }

      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[LocalNotificationService] Request permission error: $e');
    }
    return true;
  }

  String _findDeviceLocationName() {
    final name = DateTime.now().timeZoneName;
    if (tz.timeZoneDatabase.locations.containsKey(name)) {
      return name;
    }
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    if (offsetHours == 5 || offsetHours == 6) return 'Asia/Kolkata';
    if (offsetHours == -5) return 'America/New_York';
    if (offsetHours == -8) return 'America/Los_Angeles';
    if (offsetHours == 0) return 'Europe/London';
    if (offsetHours == 1) return 'Europe/Paris';
    if (offsetHours == 9) return 'Asia/Tokyo';
    return 'UTC';
  }

  tz.TZDateTime _toTzDateTime(DateTime dateTime) {
    final localDt = dateTime.toLocal();
    return tz.TZDateTime.from(localDt, tz.local);
  }

  /// Schedule a native system notification for a future date/time (Fixes BUG-006 & BUG-007)
  Future<int> scheduleNotification({
    int? notificationId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await initialize();

    final id = notificationId ?? (DateTime.now().millisecondsSinceEpoch.remainder(100000));
    final now = DateTime.now();

    if (scheduledDate.isBefore(now)) {
      debugPrint('[LocalNotificationService] Scheduled date $scheduledDate is in past. Showing immediately.');
      await showImmediateNotification(
        notificationId: id,
        title: title,
        body: body,
        payload: payload,
      );
      return id;
    }

    try {
      final scheduledTz = _toTzDateTime(scheduledDate);

      debugPrint('[LocalNotificationService] ⏰ NOW: $now');
      debugPrint('[LocalNotificationService] ⏰ REMINDER: $scheduledDate');
      debugPrint('[LocalNotificationService] ⏰ DELAY: ${scheduledDate.difference(now)}');
      debugPrint('[LocalNotificationService] ⏰ SCHEDULED_TZ: $scheduledTz');
      debugPrint('[LocalNotificationService] ⏰ NOTIF_ID: $id');

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        audioAttributesUsage: AudioAttributesUsage.notification,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        ticker: 'Priora Task Alert',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTz,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          payload: payload,
        );
      } catch (exactErr) {
        debugPrint('[LocalNotificationService] exactAllowWhileIdle failed ($exactErr), retrying with inexactAllowWhileIdle.');
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTz,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          payload: payload,
        );
      }

      debugPrint('[LocalNotificationService] ⏰ Native notification #$id scheduled for $scheduledDate ($title)');
    } catch (e) {
      debugPrint('[LocalNotificationService] ZonedSchedule error: $e');
    }

    return id;
  }

  /// Display an immediate native system notification
  Future<void> showImmediateNotification({
    int? notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    final id = notificationId ?? (DateTime.now().millisecondsSinceEpoch.remainder(100000));

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      audioAttributesUsage: AudioAttributesUsage.notification,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      ticker: 'Priora Task Alert',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      debugPrint('[LocalNotificationService] ✅ Immediate notification #$id displayed successfully ($title)');
    } catch (e, stack) {
      debugPrint('[LocalNotificationService] ❌ Immediate notification #$id error: $e\n$stack');
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notificationsPlugin.cancel(notificationId);
      debugPrint('[LocalNotificationService] Cancelled notification #$notificationId');
    } catch (e) {
      debugPrint('[LocalNotificationService] Cancel error: $e');
    }
  }

  /// Cancel multiple task notifications
  Future<void> cancelTaskNotifications(List<int> notificationIds) async {
    for (final id in notificationIds) {
      await cancelNotification(id);
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('[LocalNotificationService] Cancelled all native notifications.');
    } catch (e) {
      debugPrint('[LocalNotificationService] CancelAll error: $e');
    }
  }

  /// Get list of pending scheduled notification requests (Diagnostic Check #5)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await initialize();
    try {
      final list = await _notificationsPlugin.pendingNotificationRequests();
      debugPrint('[LocalNotificationService] 📋 Pending notification count: ${list.length}');
      for (final req in list) {
        debugPrint('  -> Pending ID #${req.id}: "${req.title}" | "${req.body}"');
      }
      return list;
    } catch (e) {
      debugPrint('[LocalNotificationService] Error fetching pending notifications: $e');
      return [];
    }
  }

  /// Check exact alarm scheduling capability on Android (Diagnostic Check #8)
  Future<bool> canScheduleExactAlarms() async {
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final enabled = await androidImpl.areNotificationsEnabled();
        debugPrint('[LocalNotificationService] ⏰ Android notifications enabled status: $enabled');
        return enabled ?? false;
      }
    } catch (e) {
      debugPrint('[LocalNotificationService] Error checking notifications capability: $e');
    }
    return true;
  }

  /// Trigger immediate test notification & schedule 5-second test alarm (Diagnostic Checks #3, #5, #6)
  Future<int> sendTestNotification() async {
    await initialize();
    await requestPermissions();

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    debugPrint('[LocalNotificationService] 🧪 Executing Test Notification Diagnostic...');

    // 1. Show immediate test alert
    await showImmediateNotification(
      notificationId: id,
      title: 'Priora Test',
      body: 'Notifications are working',
    );

    // 2. Schedule a 5-second delayed test alarm
    final scheduledId = id + 1;
    final testTime = DateTime.now().add(const Duration(seconds: 5));

    await scheduleNotification(
      notificationId: scheduledId,
      title: 'Priora 5-Sec Test',
      body: 'Scheduled reminders are working',
      scheduledDate: testTime,
    );

    // 3. Log diagnostic metrics
    await canScheduleExactAlarms();
    await getPendingNotifications();

    return scheduledId;
  }

  /// One-tap direct navigation to Android System Notification Settings
  Future<void> openNotificationSettings() async {
    try {
      await _systemSettingsChannel.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('[LocalNotificationService] Open notification settings error: $e');
    }
  }

  /// One-tap direct navigation to Android Alarms & Reminders Permission Settings
  Future<void> openExactAlarmSettings() async {
    try {
      await _systemSettingsChannel.invokeMethod('openExactAlarmSettings');
    } catch (e) {
      debugPrint('[LocalNotificationService] Open exact alarm settings error: $e');
    }
  }

  /// One-tap direct navigation to Android App Info / Hibernation Settings
  Future<void> openAppDetailsSettings() async {
    try {
      await _systemSettingsChannel.invokeMethod('openAppDetailsSettings');
    } catch (e) {
      debugPrint('[LocalNotificationService] Open app details settings error: $e');
    }
  }

  /// Triggers native Android System Dialog: "Stop optimizing battery usage? Priora will be able to run in background"
  Future<void> openBatteryOptimizationPrompt() async {
    try {
      await _systemSettingsChannel.invokeMethod('openBatteryOptimizationPrompt');
    } catch (e) {
      debugPrint('[LocalNotificationService] Open battery optimization prompt error: $e');
    }
  }

  /// Check if Priora is exempted from Android battery optimization / app hibernation
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final bool? isIgnored = await _systemSettingsChannel.invokeMethod('isBatteryOptimizationIgnored');
      return isIgnored ?? false;
    } catch (e) {
      return false;
    }
  }
}

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});
