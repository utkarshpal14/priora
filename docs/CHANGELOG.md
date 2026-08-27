# Changelog — Priora Platform

All notable changes to the Priora productivity platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.2] - 2026-08-28

### Fixed
- **GoRouter Dialog Auto-Dismissal:** Attached update modal to `rootNavigatorKey` with `useRootNavigator: true`, preventing GoRouter auth/route redirects from prematurely closing the update modal during startup.
- **Dynamic Rocket Version Card:** Replaced hardcoded `'v1.0.0 (Build 100)'` in Settings with dynamic binding to `AppConstants.appVersion` / `AppUpdateService.currentInstalledVersion`.
- **Manual In-App Update Trigger:** Unified the Settings Rocket card with an interactive **"Check for Updates"** button providing immediate visual status snackbars.
- **Android 13+ Unknown Sources Permission Resume:** Auto-triggers the APK package installer when returning from Android's "Install unknown apps" settings toggle without requiring a re-download.

### Added
- **Versioned APK Archive Engine:** Created automated `releases/vX.Y.Z/` folder structure with local APK binaries and catalog documentation.

---

## [1.1.0] - 2026-08-28

### Added
- **ENH-005 / TS-007 Custom Reminder Audio Engine:** Added 6 high-fidelity reminder sound options (`gentle_bell`, `marimba_pulse`, `zen_chime`, `crystal_ping`, `focus_bell`, `digital_alert`) with inline live audio preview in Settings.
- **ENH-006 / TS-008 In-App OTA APK Update System:**
  - Automated update check on startup comparing semantic versions against backend `/api/v1/system/app-version`.
  - In-app modal with release notes, download progress bar, cancel tokens, and error retry handlers.
  - Native Android `FileProvider` (`com.example.frontend.fileprovider`) and MethodChannel installation bridge.
- **Backend App Version System Endpoint:** Fast, cached `/api/v1/system/app-version` configuration endpoint with environment variable controls (`LATEST_APP_VERSION`, `APK_DOWNLOAD_URL`, `FORCE_APP_UPDATE`).

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
