# Milestone 11 — End-to-End Integration Testing & Cloud Push Notifications Engine

> **Status**: Approved Specification  
> **Target Version**: `v1.1.0`  
> **Prerequisites**: Milestone 10 (UI Polish & Settings System) completed & tagged `v1.0.0`

---

## 🎯 Executive Summary

Milestone 11 completes Priora's core product lifecycle by introducing:
1. A multi-layer **End-to-End Integration Test Suite** validating real user journeys from account registration to analytics reporting.
2. A dual-channel **Cloud & Local Push Notifications Engine** delivering scheduled alerts both online and offline.
3. Live **Notification Settings Wiring** connecting Settings Screen controls to backend user preferences and device token registration.

---

## 📋 Detailed Milestone Phases

### Phase 1 — End-to-End Integration Testing

#### Backend Integration Tests (`backend/tests/test_e2e_integration.py`)
Validate end-to-end user journeys rather than isolated unit endpoints:
- **Full User Journey**:
  `Register User -> Login -> Create Category -> Create Goal -> Add Milestone -> Create Task (linked to Goal & Milestone) -> Timeblock Session -> Trigger Reminder -> Complete Task -> Perform Evening Review -> Verify Analytics overview & heatmap metrics`.
- **Auth Token Refresh Cycle**:
  Login -> Token Expiry -> Call `POST /api/v1/auth/refresh` -> Validate new access token grants access to protected endpoints.
- **Attachment Storage Quota Lifecycle**:
  Create Note/Upload -> Verify `storage_used_bytes` increases -> Delete Attachment -> Verify quota is released.

#### Frontend Integration Tests (`frontend/test/e2e_integration_test.dart`)
Validate full multi-screen Riverpod controller workflows and user navigation in GoRouter:
- **User Navigation & State Flow**:
  `LoginScreen -> TasksScreen -> Create Task -> GoalsScreen -> Create Goal with Milestones -> PlannerScreen -> Schedule Timeblock -> Complete Task -> EveningReviewScreen -> AnalyticsScreen`.

---

### Phase 2 — Cloud & Local Push Notifications Engine

#### Dual Delivery Channels
1. **Local Notifications (`flutter_local_notifications`)**:
   - Must function completely offline without requiring server connection.
   - Schedules OS-level alerts directly on device using system alarms.
2. **Cloud Push Notifications (FCM / APNs)**:
   - Backend background job runner inspecting scheduled `reminders` table entries every 60 seconds.
   - Dispatches remote push notifications via FCM to registered user device tokens.

#### Reminder Types & Trigger Scenarios
- ⏰ **Scheduled Focus Session**: At timeblock start time.
- ⏳ **Upcoming Focus Block**: 15 minutes before scheduled session start.
- 🚨 **Task Due Soon**: 1 hour before task deadline.
- 🎯 **Goal Milestone Approaching**: 24 hours before milestone target date.

#### Backend Device Token Endpoints
- `POST /api/v1/users/device-token`: Register FCM/APNs push device token.
- `DELETE /api/v1/users/device-token/{token}`: Unregister token on logout.

---

### Phase 3 — Notification Settings Integration

#### Settings UI Wiring (`frontend/lib/features/settings/presentation/screens/settings_screen.dart`)
Replace the `(Coming in M11)` badge with active toggle switches:
- 🔔 **Global Notifications** (`notifications_enabled`)
- 🔊 **Sound & Haptics** (`sound_enabled`)
- 📌 **Task Deadline Reminders** (`deadline_reminders`)
- 🌙 **Daily Evening Review Reminders** (`review_reminders`)
- 🎯 **Goal Progress Alerts** (`goal_alerts`)

#### Persistence & Dual Sync
- Store preferences locally in `FlutterSecureStorage` for instant UI access.
- Sync preferences to backend user profile (`PUT /api/v1/users/profile`).

---

## 📊 Verification Criteria

1. Backend pytest integration test suite passes 100% across all multi-entity flows.
2. Frontend Flutter integration test suite passes 100%.
3. Local notifications trigger offline accurately at scheduled times.
4. FCM push notification dispatcher delivers alerts within 60 seconds of scheduled time.
5. Settings screen notification toggles accurately control alert dispatching.
