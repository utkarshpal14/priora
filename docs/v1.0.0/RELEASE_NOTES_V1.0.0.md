# Priora v1.0.0 — Official Production Release Notes

> **Release Version:** v1.0.0 (Build 100 / RC1 Approved)  
> **Release Date:** August 22, 2026  
> **Build Artifact:** `frontend/build/app/outputs/flutter-apk/app-release.apk` (58.0 MB)  

---

## 🌟 Release Highlights

Priora v1.0.0 marks the official production release of the all-in-one daily productivity workspace for Android and web platforms. This release delivers a Planner-first daily workflow, robust native notifications, live system health diagnostics, and end-to-end task and goal tracking.

---

## 🚀 Key Improvements & Fixes Included in v1.0.0

### 1. Resolved Release-Mode Notification Crash (`BLOCKER-NOTIF-001`)
- **Fix:** Preserved generic signatures (`-keepattributes Signature`) and Gson `TypeToken` serialization classes in `proguard-rules.pro`.
- **Result:** Scheduled notifications execute flawlessly in release builds without process termination or `IllegalStateException` crashes.

### 2. Restored High-Priority Reminder Engine (`BUG-006`, `BUG-007`, `BUG-008`)
- **Fix:** Configured notification channel `priora_reminders_v5` with `AndroidNotificationCategory.reminder` and `AudioAttributesUsage.notification`.
- **Result:** Resolves Android 12+ system alarm policy suppression, guaranteeing exact reminder delivery, heads-up banners, and 4.5s vibration alert patterns across locked and background states.

### 3. Live System Health & Battery Optimization Diagnostics (`UX-003`)
- **Features:** Added dynamic system health cards in Settings checking live status for:
  - `PowerManager.isIgnoringBatteryOptimizations` (Unrestricted background execution)
  - `canScheduleExactAlarms` (Exact alarm permissions)
  - One-tap deep links to native Android settings.
  - Auto-refresh upon returning from Android system settings.

### 4. Planner-First Navigation (`UX-002`)
- **Features:**
  - App launch and post-login flow automatically lands on **Today's Plan** (`/planner`).
  - Persistent bottom navigation shell highlights the **Planner** calendar tab (`index: 0`).
  - Header actions on the Planner screen provide instant access to **Settings** and **Log Out** confirmation dialogs.

---

## 📦 Installation & Verification

### Android Package Installation:
```bash
adb install -r frontend/build/app/outputs/flutter-apk/app-release.apk
```

### Verification Matrix:
- ✅ Immediate test notifications
- ✅ Scheduled reminders & overdue alerts
- ✅ Works with screen locked & backgrounded
- ✅ Dynamic battery optimization check
- ✅ 44 / 44 automated Flutter tests passed
