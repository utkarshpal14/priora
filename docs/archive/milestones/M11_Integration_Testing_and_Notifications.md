# Milestone 11 — End-to-End Integration Testing & Cloud Push Notifications Engine

> **Status**: Approved Specification  
> **Target Version**: `v1.1.0`  
> **Prerequisites**: Milestone 10 (UI Polish & Settings System) completed & tagged `v1.0.0`

---

## 🎯 Executive Summary

Milestone 11 completes Priora's core product lifecycle by introducing:
1. Multi-layer **End-to-End Integration Testing** validating real user journeys (`User -> Goal -> Milestone -> Task -> Session -> Review -> Analytics`).
2. Dual-channel **Push Notifications Infrastructure** supporting multiple device tokens per user.
3. Granular **Notification Preferences & History Audit Logs** (`notification_logs` table).
4. **Live Settings UI Wiring** connecting Settings Screen controls to backend user preferences.

---

## 🚪 Internal Gate Breakdown

```
Milestone 11
├── 🚪 Gate A: Release Critical
│    ├── End-to-End Integration Test Suite (Backend & Frontend)
│    ├── Multiple Device Token Storage (User 1:N DeviceTokens)
│    ├── Granular Notification Preferences (including session_reminders)
│    └── Local Notifications Delivery (Offline Capable)
│
└── 🚪 Gate B: Production Ready
     ├── Notification History Table (notification_logs Audit Trail)
     ├── Background Dispatcher Engine & Retry Loop
     └── Failure & Invalid Token Handling (Non-blocking queue execution)
```

---

## 📋 Gate A — Release Critical Deliverables

### A1. End-to-End Integration Test Suite
- **Backend Journey (`backend/tests/test_e2e_integration.py`)**:
  `Register User -> Login -> Create Category -> Create Goal -> Add Milestone -> Create Task -> Timeblock Session -> Schedule Reminder -> Dispatcher Executes -> Log Notification -> Complete Task -> Evening Review -> Analytics`.
- **Frontend Journey (`frontend/test/e2e_integration_test.dart`)**:
  Simulates Riverpod state sync and navigation across `TasksScreen`, `GoalsScreen`, `PlannerScreen`, `ReviewScreen`, `AnalyticsScreen`, and `SettingsScreen`.

### A2. Multiple Device Token Support (`device_tokens` Table)
A user can own multiple active device tokens (`Phone`, `Tablet`, `Web`):
```
User (id)
 ├── DeviceToken (id, token_1, platform: 'android')
 ├── DeviceToken (id, token_2, platform: 'ios')
 └── DeviceToken (id, token_3, platform: 'web')
```

### A3. Granular Notification Preferences
Preferences stored on `User` model and local preferences:
- `notifications_enabled`: Global master toggle.
- `sound_enabled`: Sound/haptics toggle.
- `deadline_reminders`: Task deadline alerts.
- `session_reminders`: Scheduled focus session alerts.
- `review_reminders`: Daily evening review prompts.
- `goal_alerts`: Goal milestone target date warnings.

### A4. Local Notifications Channel
`flutter_local_notifications` handles local device alarms offline without backend dependency.

---

## 📋 Gate B — Production Ready Deliverables

### B1. Notification History Table (`notification_logs`)

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | `UUID` | No | Primary Key |
| `user_id` | `UUID` | No | FK (`users.id` CASCADE), Index |
| `type` | `VARCHAR(50)` | No | (`SESSION`, `DEADLINE`, `REVIEW`, `GOAL`) |
| `title` | `VARCHAR(255)` | No | Notification title |
| `body` | `TEXT` | Yes | Notification content body |
| `sent_at` | `TIMESTAMPTZ` | No | Dispatch timestamp |
| `status` | `VARCHAR(20)` | No | (`SENT`, `FAILED`, `CANCELLED`) |
| `error_message` | `TEXT` | Yes | Diagnostic error string on failure |

### B2. Dispatcher Service & Resilient Failure Handling
- **Failure Resilience**:
  - Expired / Invalid Device Tokens: Remove invalid token from `device_tokens` table.
  - Network Failure / Cloud Provider Error: Log error in `notification_logs` with status `FAILED` and `error_message`.
  - Queue Protection: Errors in individual dispatches NEVER crash the dispatcher loop or block subsequent notifications.

---

## 📊 Verification Criteria

1. Backend pytest suite passes 100% with full E2E user lifecycle coverage.
2. Frontend Flutter test suite passes 100%.
3. Multiple device tokens per user can be registered and unregistered independently.
4. Scheduled reminders execute through dispatcher, update reminder status to `SENT`, and write audit logs to `notification_logs`.
5. Settings screen toggles accurately control all 5 notification preferences.
