import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl {
    final rawUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';

    // Android emulator cannot reach host PC via "localhost".
    // 10.0.2.2 is the special alias to host loopback interface on Android emulators.
    if (!kIsWeb && Platform.isAndroid) {
      return rawUrl
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }
    return rawUrl;
  }

  // Health
  static String get health => '$baseUrl/health';

  // Auth (Milestone 1 & v1.1.3 OTP)
  static String get register => '$baseUrl/auth/register';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get resendOtp => '$baseUrl/auth/resend-otp';
  static String get login => '$baseUrl/auth/login';
  static String get google => '$baseUrl/auth/google';
  static String get refresh => '$baseUrl/auth/refresh';
  static String get logout => '$baseUrl/auth/logout';

  // Users
  static String get userProfile => '$baseUrl/users/me';

  // Tasks (Milestone 2 & 3)
  static String get tasks => '$baseUrl/tasks';
  static String get categories => '$baseUrl/categories';

  // Reminders (Milestone 4)
  static String get reminders => '$baseUrl/reminders';

  // Planner (Milestone 5)
  static String get dailyPlanner => '$baseUrl/planner/day';

  // Review (Milestone 6)
  static String get dailyReview => '$baseUrl/reviews/today';

  // Goals (Milestone 7)
  static String get goals => '$baseUrl/goals';

  // Attachments (Milestone 8)
  static String get attachments => '$baseUrl/attachments';

  // Analytics (Milestone 9)
  static String get analyticsOverview => '$baseUrl/analytics/overview';
  static String get analyticsWeekly => '$baseUrl/analytics/weekly';
  static String get analyticsBreakdown => '$baseUrl/analytics/breakdown';
  static String get analyticsHeatmap => '$baseUrl/analytics/heatmap';

  // System & Version Management (ENH-006 / TS-008)
  static String get appVersion => '$baseUrl/system/app-version';
}
