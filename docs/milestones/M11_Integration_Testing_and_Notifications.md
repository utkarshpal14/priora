# Milestone 11 — End-to-End Integration Testing & Cloud Push Notifications Engine

> **Status**: Draft / Proposed  
> **Target Version**: `v1.1.0`  
> **Prerequisites**: Milestone 10 (UI Polish & Settings System) completed & tagged `v1.0.0`

---

## 🎯 Executive Summary

Milestone 11 completes Priora's core product requirements by implementing a complete End-to-End Integration Test Suite across backend API endpoints and frontend Riverpod controller flows, followed by a Cloud Push Notifications Engine (FCM / APNs / Local Notifications) integrated directly into the Settings Screen.

---

## 📋 Core Deliverables & Scope

### 1. 🧪 End-to-End Integration Test Suite
- **Backend API Integration Tests**:
  - Full lifecycle test: `Register User -> Create Category -> Create Goal -> Add Milestone -> Create Task -> Timeblock Session -> Complete Task -> Complete Review -> Check Analytics`.
  - Auth token expiry & refresh flow verification (`POST /api/v1/auth/refresh`).
  - Attachment upload, download, and storage quota enforcement tests.
- **Frontend Widget & Controller Integration Tests**:
  - Multi-screen navigation flows in GoRouter.
  - End-to-End State sync test across `TasksScreen`, `GoalsScreen`, `PlannerScreen`, and `AnalyticsScreen`.

---

### 2. 🔔 Cloud Push Notifications Engine
- **Backend Device Token Registration**:
  - `POST /api/v1/users/device-token`: Register FCM/APNs push tokens per device.
  - `DELETE /api/v1/users/device-token/{token}`: Unregister tokens on logout.
- **Scheduled Push Dispatcher**:
  - Background cron/job runner checking pending `reminders` table entries every minute.
  - Dispatch push notifications when `remind_at <= current_timestamp` and update status to `SENT`.

---

### 3. ⚙️ Notification Settings Integration
- **Frontend Settings Wiring**:
  - Replace `(Coming in M11)` badge in `SettingsScreen` with live, functional toggle switches:
    - Task Deadline Reminders
    - Daily Evening Review Reminders
    - Goal Progress Alerts
  - Persist notification preferences via backend user profile settings.

---

## 📊 Verification Criteria

1. Backend pytest suite passes 100% with integration test coverage for all multi-entity flows.
2. Flutter test suite passes 100% with full widget integration coverage.
3. Push notification dispatcher delivers alerts within 60 seconds of scheduled `remind_at` time.
