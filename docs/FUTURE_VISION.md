# Priora — Future Version Ideas & Backlog (v2 Vision)

## Purpose

This document contains features intentionally postponed from the MVP roadmap.

These features are not required for Priora v1 launch but may be implemented in future versions based on user feedback, usage patterns, and project growth.

---

# Version 2 Candidates

---

# 1. Project Planning System

## Status
Deferred

## Priority
High

## Reason Deferred
Not required for MVP. Current task and planner system already support deadlines, reminders, and daily planning. This feature introduces a new layer of planning complexity.

---

## Problem
Large projects cannot be effectively managed as a single task.

Examples:
- Striver A2Z Sheet
- DNN Journey
- ML Course
- Semester Preparation
- Placement Preparation
- Certification Roadmaps

Users may want to manually break projects into:
- Monthly targets
- Weekly targets
- Daily targets

---

## Proposed Structure

```text
Project
│
├── Monthly Plans
│
├── Weekly Plans
│
├── Daily Plans
│
└── Progress Tracking
```

---

## Example

```text
Project: Striver A2Z Sheet
Deadline: 31 Dec 2026
```

Monthly:
```text
September: Arrays
October: Strings
November: Linked List
```

Weekly:
```text
Week 1: 15 Questions
```

Daily:
```text
Today: Two Sum, Kadane, Majority Element
```

---

## Important Rules
- No AI-generated breakdowns.
- User manually creates plans.
- User manually updates progress.
- Planner may optionally show daily project targets.
- Separate from normal task management.

---

# 2. Cloud Push Notifications (FCM)

## Status
Deferred

## Priority
Medium

## Reason Deferred
Local notifications are sufficient for MVP. FCM increases infrastructure complexity, Firebase dependency, device token management, and backend scheduler requirements.

---

## Future Features
- Push notifications from cloud
- Cross-device notifications
- Offline reminder synchronization
- Scheduled push delivery

---

## Required Components
- Firebase Cloud Messaging (FCM)
- UserDevice table
- Device token management
- Notification worker
- Push queue

---

# 3. Backend Notification Scheduler

## Status
Deferred

## Priority
Medium

## Reason Deferred
Local notifications already provide reminder functionality.

---

## Future Features
- Scheduled reminder dispatching
- Missed reminder recovery
- Push retry system
- Background worker infrastructure

---

# 4. AI Productivity Assistant

## Status
Deferred

## Priority
Low

## Reason Deferred
Priora MVP intentionally avoids AI dependence.

---

## Possible Future Features
- Task prioritization suggestions
- Productivity insights
- Workload balancing
- Smart scheduling recommendations
- Daily planning suggestions

---

## Important
AI must never automatically modify tasks. User remains in control.

---

# 5. AI Goal Breakdown

## Status
Deferred

## Priority
Low

## Reason Deferred
User specifically requested manual planning.

---

# 6. Recurring Tasks

## Status
Deferred (Planned v1.1)

## Priority
High

## Reason Deferred
Not necessary for MVP launch.

---

## Examples
- Daily: DSA Practice
- Weekly: Revision Session
- Monthly: Resume Update

---

# 7. Habit Tracker

## Status
Deferred (Planned v1.1)

## Priority
Medium

---

# 8. Calendar Integrations

## Status
Deferred

## Priority
Low

- Google Calendar
- Outlook Calendar
- Apple Calendar

---

# 9. Desktop Application

## Status
Deferred

## Priority
Medium

- Windows, macOS, Linux native distributions.

---

# 10. Team / Shared Workspaces

## Status
Deferred

## Priority
Low

- Shared projects, team planning, task assignment.

---

# 11. Email Notifications

## Status
Deferred

## Priority
Low

- Reminder emails, daily summaries, weekly reviews.

---

# 12. Advanced Analytics

## Status
Partially Deferred

## Priority
Medium

- Productivity heatmaps, focus-time analytics, completion trends.

---

# 13. Attachments Storage Upgrade

## Status
Deferred

## Priority
Medium

- Cloud file storage, PDF previews, OCR scanning.

---

# 14. Offline Sync Engine

## Status
Deferred

## Priority
High

- Full offline mode with background conflict resolution.

---

# 15. Wearable Support

## Status
Deferred

## Priority
Low

- Android Wear OS, Apple Watch apps.

---

# 16. ENH-004 — Custom Reminder Audio Playback

## Status
Completed in v1.1.0

---

# 17. Email Verification & OTP Verification Gate

## Status
Planned for Future Vision (Post-v1.1.0)

## Priority
Medium-High

## Objective
Prevent registration with fake or non-existent email addresses.

## Requirements
- Send a 6-digit One-Time Password (OTP) or magic confirmation link to user's registered email via SMTP / Resend / SendGrid / Supabase Auth.
- Gate access: require `is_email_verified = True` before issuing session access tokens or logging in via email/password.
- Provide "Resend OTP" functionality with rate-limiting.

---

# 18. Native One-Tap Google Sign-In

## Status
Planned for Future Vision (Post-v1.1.0)

## Priority
High

## Objective
Allow users to log in or register with a single click using their device's Google Account.

## Requirements
- Integrate native Google Sign-In SDK on Android and Google Identity Services on Web.
- One tap opens the native system account bottom sheet to select any logged-in Google account on the device.
- Exchanges Google ID token with backend `POST /api/v1/auth/google`.
- Automatically marks `is_email_verified = True` and auto-populates user's name and avatar.

---

# MVP Boundary (Locked)

The following are NOT required before current milestone launch:
- ❌ AI Assistant
- ❌ AI Goal Breakdown
- ❌ Project Planning System
- ❌ FCM Push Infrastructure
- ❌ Team Collaboration
- ❌ Habit Tracker
- ❌ Calendar Integrations
- ❌ Desktop App
- ❌ Wearables

---

# MVP Focus (Locked)

The focus remains:
- ✅ Tasks
- ✅ Deadlines
- ✅ Reminders
- ✅ Planner
- ✅ Reviews
- ✅ Goals
- ✅ Analytics
- ✅ Attachments
- ✅ Production Release
