import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/notification_preferences_model.dart';

class NotificationSettingsController extends StateNotifier<NotificationPreferencesModel> {
  final ApiClient? _apiClient;

  NotificationSettingsController([this._apiClient])
      : super(const NotificationPreferencesModel()) {
    _fetchPreferences();
  }

  Future<void> _fetchPreferences() async {
    if (_apiClient == null) return;
    try {
      final response = await _apiClient.get('/api/v1/users/notification-preferences');
      if (response.data != null && response.data['data'] != null) {
        state = NotificationPreferencesModel.fromJson(response.data['data']);
      }
    } catch (_) {
      // Fallback to default state if unauthenticated or offline
    }
  }

  Future<void> toggleGlobalNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _syncPreferences();
  }

  Future<void> toggleSound(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await _syncPreferences();
  }

  Future<void> toggleDeadlineReminders(bool value) async {
    state = state.copyWith(deadlineReminders: value);
    await _syncPreferences();
  }

  Future<void> toggleSessionReminders(bool value) async {
    state = state.copyWith(sessionReminders: value);
    await _syncPreferences();
  }

  Future<void> toggleReviewReminders(bool value) async {
    state = state.copyWith(reviewReminders: value);
    await _syncPreferences();
  }

  Future<void> toggleGoalAlerts(bool value) async {
    state = state.copyWith(goalAlerts: value);
    await _syncPreferences();
  }

  Future<void> _syncPreferences() async {
    if (_apiClient == null) return;
    try {
      await _apiClient.put(
        '/api/v1/users/notification-preferences',
        data: state.toJson(),
      );
    } catch (_) {
      // Silent error logging
    }
  }

  Future<bool> registerDeviceToken(String token, [String platform = 'android']) async {
    if (_apiClient == null) return false;
    try {
      await _apiClient.post(
        '/api/v1/users/device-token',
        data: {'token': token, 'platform': platform},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsController, NotificationPreferencesModel>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationSettingsController(apiClient);
});
