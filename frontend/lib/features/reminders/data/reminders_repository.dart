import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reminder_model.dart';
import 'reminders_api.dart';

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  final api = ref.watch(remindersApiProvider);
  return RemindersRepository(api);
});

class RemindersRepository {
  final RemindersApi _api;

  RemindersRepository(this._api);

  Future<ReminderModel> createReminder({
    required String taskId,
    required DateTime remindAt,
    int? notificationId,
  }) async {
    return _api.createReminder(
      taskId: taskId,
      remindAt: remindAt,
      notificationId: notificationId,
    );
  }

  Future<List<ReminderModel>> getReminders({
    String? taskId,
    String? status,
  }) async {
    return _api.getReminders(taskId: taskId, status: status);
  }

  Future<ReminderModel> getReminder(String id) async {
    return _api.getReminder(id);
  }

  Future<ReminderModel> updateReminder(
    String id, {
    DateTime? remindAt,
    String? status,
    int? notificationId,
  }) async {
    return _api.updateReminder(
      id,
      remindAt: remindAt,
      status: status,
      notificationId: notificationId,
    );
  }

  Future<void> deleteReminder(String id) async {
    return _api.deleteReminder(id);
  }
}
