# Changelog — Priora Platform

All notable changes to the Priora productivity platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-08-22

### Added
- **Planner-First Experience (`/planner`):** Made the Hourly Timeline Planner the default home screen upon launch and authentication with persistent bottom navigation shell integration (`UX-002`).
- **Header Action Shortcuts:** Added direct Settings (`Icons.settings_outlined`) and Log Out (`Icons.logout_rounded`) action buttons on the Planner screen header.
- **UX-003 Reminder Health & System Diagnostics:** Added dynamic system health cards in Settings checking live status for `PowerManager.isIgnoringBatteryOptimizations` and `canScheduleExactAlarms` with auto-refresh on returning from Android system settings.
- **Custom Vibration Pattern:** Added 4.5s custom vibration sequence (`[0, 1000, 500, 1000, 500, 1000]`) to all high-priority reminder notifications.
- **Virtual Time-Block Scheduling:** Tapping any empty hour on the Planner timeline opens `ScheduleTimeSlotDialog` to create `TaskSession` blocks.
- **Smart Urgency Banner:** Real-time visual alert for tasks approaching deadline within 2 hours or currently overdue.
- **Goal Tracking & Sub-Goals:** Added goal target dates, progress bar calculations, and sub-goal checklists.
- **Evening Review Routine:** Daily review workflow for reflecting on completed tasks, rescheduling pending items, and recording daily focus ratings.

### Fixed
- **BLOCKER-NOTIF-001 (Release R8 Crash):** Fixed Gson `TypeToken` generic signature stripping in ProGuard release builds by adding `-keepattributes Signature` and `-keep class com.google.gson.** { *; }` to `proguard-rules.pro`.
- **BUG-006 & BUG-007 (Notification Delivery Failure):** Restored high-priority notification delivery on channel `priora_reminders_v5` using `AndroidNotificationCategory.reminder` and `AudioAttributesUsage.notification` to eliminate Android 12+ system alarm policy suppression.
- **BUG-008 (Android Notification Permission):** Ensured native `POST_NOTIFICATIONS` runtime permission prompt triggers on launch and syncs cleanly with Android settings.
- **BUG-002 & BUG-003 (Input Text Contrast):** Fixed text contrast issues on task search bar and task title input fields across light, dark, and device-specific theme modes.

### Changed
- Converted `SettingsScreen` to `ConsumerStatefulWidget` with `WidgetsBindingObserver` to auto-refresh system health status when resuming from system settings.
- Upgraded `local_notification_service.dart` channel ID to `priora_reminders_v5`.
