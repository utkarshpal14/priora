# Priora v1.0.0-RC1 — Manual QA Bug & Issue Report

> **Testing Phase:** Release Candidate 1 (RC1)  
> **Platform:** Android  
> **Tester:** Utkarsh Pal  
> **Date:** August 22, 2026  
> **Build:** v1.0.0 / RC1 APK  
> **Status:** Notification Engine APPROVED for Release  
> **Purpose:** Track issues discovered during real-device manual QA before production release.

---

# Issue Summary

| ID | Area | Severity | Type | Status |
|---|---|---|---|---|
| BLOCKER-NOTIF-001 | Android Scheduled Notifications | P0 (Blocker) | Runtime Crash / Delivery Failure | **RESOLVED & RELEASE READY** |
| BUG-006 | Notifications / Reminder Delivery | Critical | Bug | **RESOLVED & RELEASE READY** |
| BUG-007 | Notifications / Overdue Alerts | High | Bug | **RESOLVED & RELEASE READY** |
| BUG-008 | Android Notification Permission | Critical | Bug / Configuration | **RESOLVED & RELEASE READY** |
| UX-003 | Reminder Diagnostics & Permission Check | Medium | UX Improvement | **INCLUDED IN v1.0.0** |
| ENH-004 | Custom Reminder Audio Playback | Low | Feature Enhancement | Tracked (v1.1 Backlog) |
| BUG-001 | Authentication / Task Loading | High | Bug | Retest |
| BUG-002 | Search UI / Theme | Medium | Bug | Retest |
| BUG-003 | Task Creation UI / Theme | Medium | Bug | Retest |
| BUG-004 | Planner / Task Session Editing | High | Bug | Retest (Virtual Session & Persistence Fix Applied) |
| BUG-005 | Planner / Focus Action | High | Bug | Retest |
| UX-001 | Planner UI / Usability | Medium | UX Improvement | Retest |
| UX-002 | Navigation / Default Landing Page | Medium | Product/UX Improvement | Retest |

---

# 🎉 RESOLVED & RELEASE READY: Notification Engine

**Status:** **PASSED PHYSICAL DEVICE TESTING (100% RELEASE READY)**

### Verified Working Capabilities:
- ✅ Immediate test notifications
- ✅ Scheduled task reminders
- ✅ Deadline & overdue alerts
- ✅ Operates with screen locked
- ✅ Operates in background
- ✅ Sound & vibration delivery
- ✅ Zero crashes / Zero process terminations
- ✅ Exact reminder delivery verified on physical Android device

### Resolution Technical Summary:
- **R8 ProGuard Fix:** Added `-keepattributes Signature` and `-keep class com.google.gson.** { *; }` to `proguard-rules.pro`, permanently fixing Gson `TypeToken` generic signature stripping.
- **Manifest Receiver Export:** Configured `ScheduledNotificationReceiver` with `android:exported="true"`.
- **Channel Reset (`priora_reminders_v5`):** Restored `AndroidNotificationCategory.reminder` and `AudioAttributesUsage.notification` to prevent Android 12+ OS system alarm suppression.

---

# 🚀 Included in Priora v1.0.0

### UX-003 — Reminder Diagnostics & System Health
- **Live System Health Indicators:** Live checks for Notification Permission, Exact Alarm Permission, and PowerManager Battery Optimization.
- **Auto-Refresh:** Dynamically updates when returning from Android System Settings (`AppLifecycleState.resumed`).
- **One-Tap Deep Links:** Direct navigation to Android System Notification, Exact Alarm, and App Info settings.
- **Heads-up Notifications & Vibration Pattern:** High-priority floating banners with custom ~4.5–5s vibration pattern (`[0, 1000, 500, 1000, 500, 1000]`).

---

# 🔮 Tracked Future Enhancement (v1.1 Backlog)

### ENH-004 — Custom Reminder Audio Playback
- **Scope:**
  - 5-second custom reminder audio chime
  - Optional 10-second strong alert
  - User-configurable reminder intensity (Silent, Standard, Enhanced 5s, Strong 10s)

---

# Cross-Cutting QA Notes & Sign-Off

| Role | Name | Date | Status |
|---|---|---|---|
| Tester | Utkarsh Pal | August 22, 2026 | **NOTIFICATIONS VERIFIED & APPROVED** |
| Developer | Antigravity AI | August 22, 2026 | **FIXES APPLIED & TESTED (44/44 PASSED)** |
