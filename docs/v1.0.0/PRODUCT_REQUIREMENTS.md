# Priora — Product Requirements Document (PRD)

> **Version:** v1.0.0 (Build 100 / RC1 Approved)  
> **Status:** Finalized & Implemented  
> **Scope:** Full v1.0.0 Production Release Requirements  

---

## 1. Overview & Objectives

This document establishes the functional, non-functional, and usability requirements for **Priora v1.0.0**. All requirements documented here have been implemented, validated across automated tests, and verified on physical Android hardware.

---

## 2. Core Functional Modules

### Module 1: Authentication & User Session
- **FR-1.1 Email Registration & Login:** Users can create accounts and authenticate via email/password credentials.
- **FR-1.2 Google Sign-In:** Users can register and sign in seamlessly via Google OAuth2 credentials.
- **FR-1.3 Session Restoration:** On app startup, stored JWT tokens are validated asynchronously to restore user state without forcing re-login.
- **FR-1.4 Logout & Cleanup:** Sign-out invalidates local session tokens, purges secure storage, and returns the user to `/login`.

### Module 2: Task Management & Organization
- **FR-2.1 Task Creation & Editing:** Users can create and edit tasks with title, description, category, priority (High, Medium, Low), deadline, and estimated duration.
- **FR-2.2 Task Filtering:** Users can filter tasks by category, status (All, Pending, Completed, Overdue), and search query string.
- **FR-2.3 Smart Urgency Banner:** Displays real-time warnings for tasks approaching deadline within 2 hours or currently overdue.
- **FR-2.4 Task Completion:** Toggling task completion immediately updates progress indicators and recalculates overdue counters.

### Module 3: Hourly Planner & Time Blocking (Default Home Screen)
- **FR-3.1 Default Navigation Target:** Upon login or launch, the app routes directly to `/planner` as the primary home screen.
- **FR-3.2 Calendar Strip:** Horizontal scrollable date picker allowing users to select any day of the week and view scheduled workload indicators.
- **FR-3.3 Hourly Timeline Section:** Visual timeline displaying scheduled `TaskSession` blocks (e.g. 09:00 AM - 10:30 AM), active time indicators, and unscheduled task drop areas.
- **FR-3.4 Virtual Time-Block Creation:** Tapping any empty hour slot opens the `ScheduleTimeSlotDialog`, permitting instant session scheduling.
- **FR-3.5 Top 3 Focus Priorities:** Highlights the top 3 high-priority tasks requiring immediate attention for the selected day.
- **FR-3.6 Evening Review Banner:** Displays end-of-day summary banner prompting users to review completed and pending tasks.

### Module 4: Native Notification Engine & System Health (`UX-003`)
- **FR-4.1 Instant Notifications:** Sends immediate heads-up banner notifications for instant system alerts.
- **FR-4.2 Scheduled Task Reminders:** Schedules exact wall-clock notifications for preset offsets (e.g., 15 mins before deadline, 1 hour before deadline) via `zonedSchedule`.
- **FR-4.3 Overdue Task Notifications:** Triggers automatic alerts when tasks pass their configured deadline.
- **FR-4.4 Heads-Up Banner & Vibration:** All notifications utilize `priora_reminders_v5` channel with `Importance.max`, `Priority.max`, `visibility: public`, and a 4.5s custom vibration pattern `[0, 1000, 500, 1000, 500, 1000]`.
- **FR-4.5 Live System Health Card (`UX-003`):** Dedicated settings section checking and displaying live status for:
  - Notification Permission (`POST_NOTIFICATIONS`)
  - Battery Optimization (`PowerManager.isIgnoringBatteryOptimizations`)
  - Exact Alarm Capability (`canScheduleExactAlarms`)
  - One-tap system settings deep links.

### Module 5: Goal Tracking
- **FR-5.1 Goal Management:** Users can define long-term goals with target dates, target metrics, and linked tasks.
- **FR-5.2 Sub-Goal Breakdown:** Allows users to break goals into manageable sub-goals with independent completion checkboxes.
- **FR-5.3 Progress Calculation:** Dynamic calculation of overall goal completion percentage based on sub-goal and task progress.

### Module 6: Evening Review Routine
- **FR-6.1 Daily Review Workflow:** Interactive step-by-step review flow allowing users to inspect completed work, reschedule incomplete tasks, and log daily focus reflection notes.
- **FR-6.2 Review Celebration Screen:** End-of-review modal showing completion stats recap and streak updates.

### Module 7: Analytics & Performance Metrics
- **FR-7.1 Productivity Dashboard:** Visual charts displaying daily completion velocity, category workload distribution, and weekly trends.
- **FR-7.2 Real-Time Metrics:** Computes total tasks completed, on-time completion percentage, and overdue resolution rates.

---

## 3. Non-Functional Requirements (NFRs)

### Performance & Latency
- **NFR-1.1 Cold Start Time:** Application main view renders within 1.5 seconds on standard Android hardware.
- **NFR-1.2 Local UI State Update:** Task checkbox toggles and time-block edits execute with zero UI lag (< 16ms frame render).

### Reliability & Release Build Integrity (`BLOCKER-NOTIF-001`)
- **NFR-2.1 R8 Shrinker Safety:** Production release builds retain generic signature types for Gson `TypeToken` deserialization in `ScheduledNotificationReceiver`, preventing release-mode crashes.
- **NFR-2.2 Notification Delivery Rate:** 100% notification delivery accuracy for exact scheduled reminders when battery optimization is exempted.

### Usability & Accessibility
- **NFR-3.1 Theme Adaptability:** Full support for Light, Dark, and System Theme modes with dynamic accent color selection.
- **NFR-3.2 Input Text Contrast:** High-contrast text rendering on all text input fields across light/dark backgrounds (`BUG-002`, `BUG-003`).
