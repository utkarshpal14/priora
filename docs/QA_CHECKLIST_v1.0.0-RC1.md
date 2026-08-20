# QA Checklist — Priora v1.0.0-RC1 (Release Candidate 1)

> **Target Version**: `v1.0.0-RC1`  
> **Date**: August 20, 2026  
> **Environment**: Staging / Pre-Production QA  
> **Target Platforms**: Web, Android, iOS, Windows, Backend (FastAPI / SQLite / PostgreSQL)  
> **Release Criteria**: 100% Automated Test Pass Rate + 100% Manual QA Sign-off on Critical Path Flows  

---

## 📋 Table of Contents
1. [Automated Testing Gate Summary](#1-automated-testing-gate-summary)
2. [Authentication & User Isolation QA](#2-authentication--user-isolation-qa)
3. [Tasks & Priority Matrix QA](#3-tasks--priority-matrix-qa)
4. [Planner & Time-Blocking QA](#4-planner--time-blocking-qa)
5. [Goals & Milestones Roadmap QA](#5-goals--milestones-roadmap-qa)
6. [End-of-Day Review QA](#6-end-of-day-review-qa)
7. [Resource Attachments & Quota QA](#7-resource-attachments--quota-qa)
8. [Analytics & Heatmap Metrics QA](#8-analytics--heatmap-metrics-qa)
9. [Notifications & Multi-Device Push QA (M11)](#9-notifications--multi-device-push-qa-m11)
10. [Theme Engine & Accessibility QA](#10-theme-engine--accessibility-qa)
11. [Network, Security & Resilience QA](#11-network-security--resilience-qa)
12. [Release Sign-off Decision Matrix](#12-release-sign-off-decision-matrix)

---

## 1. Automated Testing Gate Summary

Before executing manual QA test cases, all automated test suites must pass without error.

- [x] **Backend Unit & Integration Test Suite**
  - **Command**: `.venv\Scripts\pytest.exe`
  - **Pass Criteria**: `61 / 61 tests passed` (0 failures, 0 errors)
  - **Coverage Scope**: Auth, Tasks, Categories, Planner, Reminders, Goals, Review, Analytics, Attachments, Notifications Dispatcher, Multi-Device Tokens, E2E Workflow.

- [x] **Frontend Unit, Widget & Integration Test Suite**
  - **Command**: `flutter test`
  - **Pass Criteria**: `44 / 44 tests passed` (0 failures, 0 errors)
  - **Coverage Scope**: App Router, Theme Controller, Reusable Empty/Error Views, Tasks Controller, Timeblock Timeline, Notification Settings Controller.

---

## 2. Authentication & User Isolation QA

| ID | Test Scenario | Steps to Reproduce | Expected Result | Pass/Fail |
|:---|:---|:---|:---|:---:|
| **AUTH-01** | User Registration | 1. Enter email, password, full name.<br>2. Submit form. | Account created, access/refresh tokens returned, redirected to Dashboard. | [ ] |
| **AUTH-02** | User Login | 1. Enter valid credentials.<br>2. Submit login form. | JWT stored securely, session established. | [ ] |
| **AUTH-03** | Auto Token Refresh | 1. Let access token expire (or mock 401).<br>2. Perform API action. | Dio interceptor transparently exchanges refresh token and succeeds without logging user out. | [ ] |
| **AUTH-04** | Session Persistence | 1. Close app / refresh browser.<br>2. Re-open app. | User remains logged in automatically without re-entering credentials. | [ ] |
| **AUTH-05** | Strict User Isolation | 1. Log in as User A, create task.<br>2. Log in as User B. | User B cannot view, query, or edit User A's tasks, goals, or attachments. | [ ] |
| **AUTH-06** | Logout | 1. Tap Settings -> Logout. | Local tokens cleared, user redirected to Login screen. | [ ] |

---

## 3. Tasks & Priority Matrix QA

| ID | Test Scenario | Steps to Reproduce | Expected Result | Pass/Fail |
|:---|:---|:---|:---|:---:|
| **TASK-01** | Task Creation | 1. Tap + Task.<br>2. Enter title, deadline, priority, category. | Task created successfully and rendered in task list. | [ ] |
| **TASK-02** | Priority Badge & Color | 1. View task list with `LOW`, `MEDIUM`, `HIGH`, `CRITICAL` tasks. | Priority badges render distinct, high-contrast colors matching design system. | [ ] |
| **TASK-03** | Overdue Urgency Banner | 1. Set task deadline in past.<br>2. View Tasks / Overdue tab. | Red Smart Urgency Banner displays task count and alert styling. | [ ] |
| **TASK-04** | Category Filtering | 1. Select specific Category chip in task filter bar. | List updates dynamically showing only tasks under selected category. | [ ] |
| **TASK-05** | Task Completion Toggle | 1. Check task checkbox. | Task status transitions to `COMPLETED`, strike-through style applied, completed count increments. | [ ] |
| **TASK-06** | Empty State Verification | 1. Delete or complete all tasks. | `AppEmptyView` renders with celebration message and "Create your first task" action. | [ ] |

---

## 4. Planner & Time-Blocking QA

| ID | Test Scenario | Steps to Reproduce | Expected Result | Pass/Fail |
|:---|:---|:---|:---|:---:|
| **PLAN-01** | Hourly Timeline View | 1. Navigate to Planner tab. | 24-hour timeline renders with current time indicator line. | [ ] |
| **PLAN-02** | Schedule Time Block | 1. Select task, set start & end time. | Time block renders as colored card on timeline. | [ ] |
| **PLAN-03** | Conflict Detection | 1. Attempt to schedule overlapping time block. | System flags interval overlap and displays conflict indicator badge. | [ ] |
| **PLAN-04** | Move Task to Today | 1. Tap "Move to Today" on backlog task. | Task deadline updates to current day and appears in today's planner plan. | [ ] |
| **PLAN-05** | Reschedule Session Window | 1. Edit existing session start/end time. | Session card smoothly adjusts height and position on timeline. | [ ] |

---

## 5. Goals & Milestones Roadmap QA

| ID | Test Scenario | Steps to Reproduce | Expected Result | Pass/Fail |
|:---|:---|:---|:---|:---:|
| **GOAL-01** | Create Goal with Milestones | 1. Create goal with target date & 3 sub-milestones. | Goal created with initial 0% progress bar. | [ ] |
| **GOAL-02** | Check Milestone Completion | 1. Check off 1 of 2 milestones. | Goal progress bar updates dynamically to 50%. | [ ] |
| **GOAL-03** | Link Task to Goal & Milestone | 1. Create task, link to Goal X / Milestone Y. | Task appears under goal breakdown view. | [ ] |
| **GOAL-04** | Complete Goal Roadmap | 1. Complete all sub-milestones and linked tasks. | Goal updates to `COMPLETED` with celebration badge. | [ ] |

---

## 6. End-of-Day Review QA

| ID | Test Scenario | Steps to Reproduce | Expected Result | Pass/Fail |
|:---|:---|:---|:---|:---:|
| **REV-01** | Evening Review Workflow | 1. Open Review screen at end of day. | Summary shows completed vs incomplete tasks and completion percentage. | [ ] |
| **REV-02** | Mood & Reflection Input | 1. Select 5-star rating.<br>2. Write reflection notes.<br>3. Submit. | Review entry saved, celebration dialog shown. | [ ] |
| **REV-03** | Batch Reschedule Incomplete Tasks | 1. Move task to tomorrow / next week in review flow. | Deadlines updated in batch operation cleanly. | [ ] |

---

## 7. Resource Attachments & Quota QA

| ID | Test Scenario | Steps to Reproduce | Expected Result | Pass/Fail |
|:---|:---|:---|:---|:---:|
| **ATT-01** | Note Attachment | 1. Add Markdown note to task. | Note saved, rendered with rich formatting preview. | [ ] |
| **ATT-02** | Web Link Preview | 1. Add URL attachment (e.g. GitHub link). | OpenGraph card renders title, description, and link icon. | [ ] |
| **ATT-03** | File / Image Upload | 1. Upload image/doc attachment. | File saved, thumbnail/download link generated. | [ ] |
| **ATT-04** | Storage Quota Tracking | 1. Check user storage usage meter in Settings/Attachments. | Meter accurately reflects `storage_used_bytes` / quota limit. | [ ] |

---

## 8. Analytics & Heatmap Metrics QA

| ID | Test Scenario | Steps to Reproduce | Expected Result | Pass/Fail |
|:---|:---|:---|:---|:---:|
| **ANA-01** | Streak Calculation | 1. Complete tasks on consecutive days. | Current streak count increments accurately. | [ ] |
| **ANA-02** | Activity Heatmap | 1. View Analytics heatmap calendar. | Color density levels correspond to daily completion volume. | [ ] |
| **ANA-03** | Timezone Offset (`tz_offset`) | 1. Change device timezone.<br>2. Fetch analytics. | Daily counts align accurately with user local timezone boundaries. | [ ] |

---

## 9. Notifications & Multi-Device Push QA (M11)

| ID | Test Scenario | Steps to Reproduce | Expected Result | Pass/Fail |
|:---|:---|:---|:---|:---:|
| **NOTIF-01** | Register Device Token | 1. Log in on Android device / browser. | FCM token registered to user (`DeviceToken` table). | [ ] |
| **NOTIF-02** | Multi-Device Token List | 1. Log in on secondary phone/tablet. | Both device tokens stored under user account without overwriting. | [ ] |
| **NOTIF-03** | Toggle Notification Preferences | 1. Go to Settings -> Notifications.<br>2. Toggle Task Deadlines / Review Reminders. | Settings persist to backend via `PUT /api/v1/users/notification-preferences`. | [ ] |
| **NOTIF-04** | Dispatcher Loop Audit | 1. Trigger scheduled reminder execution. | Notification dispatched, record written to `NotificationLog` (`status=SENT`). | [ ] |
| **NOTIF-05** | Dispatcher Error Resilience | 1. Simulate invalid FCM token / timeout. | Error logged to `NotificationLog` (`status=FAILED`), queue execution continues. | [ ] |

---

## 10. Theme Engine & Accessibility QA

| ID | Test Scenario | Steps to Reproduce | Expected Result | Pass/Fail |
|:---|:---|:---|:---|:---:|
| **THEME-01** | Light / Dark / System Switch | 1. Select Light, Dark, or System mode in Settings. | Complete app UI re-colors instantly across all screens. | [ ] |
| **THEME-02** | Accent Color Switching | 1. Select Indigo, Blue, Green, Orange, Purple. | Primary active buttons, switches, and highlights update color palette. | [ ] |
| **THEME-03** | Reduce Motion Toggle | 1. Enable "Reduce Motion" in Settings. | Animations, shimmers, and dynamic transitions switch to minimal motion mode. | [ ] |
| **THEME-04** | High-Contrast Contrast Audit | 1. Inspect text and background in dark mode. | All primary text elements comply with WCAG 2.1 AA contrast ratios. | [ ] |

---

## 11. Network, Security & Resilience QA

| ID | Test Scenario | Steps to Reproduce | Expected Result | Pass/Fail |
|:---|:---|:---|:---|:---:|
| **NET-01** | Offline / Disconnected Behavior | 1. Disable network during app use. | `AppErrorView` or offline retry snackbar displays gracefully without crashing. | [ ] |
| **NET-02** | Server 500 / API Error Handling | 1. Mock API 500 internal server error. | UI renders user-friendly `AppErrorView` with retry button. | [ ] |
| **NET-03** | SQL Injection & Payload Sanitization | 1. Submit malicious strings in task titles/notes. | Inputs sanitized, stored, and escaped safely. | [ ] |

---

## 12. Release Sign-off Decision Matrix

To approve `v1.0.0-RC1` for production release tagging (`v1.0.0`), all items below must be signed off by the Lead QA Engineer and Lead Architect.

- [x] **Automated Tests**: 100% Pass Rate (Backend 61/61, Frontend 44/44)
- [ ] **Critical Path Manual QA**: 100% Pass Rate (AUTH, TASK, PLAN, GOAL, NOTIF)
- [ ] **Accessibility & UI Audit**: Approved
- [ ] **Security & Isolation Verification**: Approved

| Role | Sign-off Name | Date | Status |
|:---|:---|:---|:---:|
| **Lead Developer** | Utkarsh Pal | August 20, 2026 | **APPROVED** |
| **QA Lead** | ____________________ | ____________ | **PENDING MANUAL VERIFICATION** |
| **Release Manager** | ____________________ | ____________ | **PENDING MANUAL VERIFICATION** |
