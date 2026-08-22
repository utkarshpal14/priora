# Priora — Future Versions & Backlog

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

Not required for MVP.

Current task and planner system already support deadlines, reminders, and daily planning.

This feature introduces a new layer of planning complexity.

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
Project:
Striver A2Z Sheet

Deadline:
31 Dec 2026
```

Monthly:

```text
September
- Arrays

October
- Strings

November
- Linked List
```

Weekly:

```text
Week 1
- 15 Questions
```

Daily:

```text
Today
- Two Sum
- Kadane
- Majority Element
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

Local notifications are sufficient for MVP.

FCM increases:

- Infrastructure complexity
- Firebase dependency
- Device token management
- Backend scheduler requirements

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

AI must never automatically modify tasks.

User remains in control.

---

# 5. AI Goal Breakdown

## Status

Deferred

## Priority

Low

## Reason Deferred

User specifically requested manual planning.

---

## Example

Not implemented:

```text
Goal:
Complete DNN Course

AI Suggests:
- Month 1
- Month 2
- Month 3
```

User must create plans manually.

---

# 6. Recurring Tasks

## Status

Deferred

## Priority

High

## Reason Deferred

Not necessary for MVP launch.

---

## Examples

```text
Daily:
DSA Practice
```

```text
Weekly:
Revision Session
```

```text
Monthly:
Resume Update
```

---

## Recurrence Types

- Daily
- Weekly
- Monthly
- Custom

---

# 7. Habit Tracker

## Status

Deferred

## Priority

Medium

## Reason Deferred

Separate productivity domain.

---

## Examples

- Drink Water
- Exercise
- Meditation
- Reading
- DSA Daily

---

## Future Metrics

- Streaks
- Consistency Score
- Monthly Completion

---

# 8. Calendar Integrations

## Status

Deferred

## Priority

Low

---

## Integrations

- Google Calendar
- Outlook Calendar
- Apple Calendar

---

## Features

- Sync deadlines
- Import events
- Calendar overlays

---

# 9. Desktop Application

## Status

Deferred

## Priority

Medium

---

## Platforms

- Windows
- macOS
- Linux

---

## Notes

Flutter already supports desktop.

Can be released after mobile MVP stabilizes.

---

# 10. Team / Shared Workspaces

## Status

Deferred

## Priority

Low

---

## Features

- Shared projects
- Shared task lists
- Team planning
- Task assignment

---

## Notes

Priora MVP is single-user focused.

---

# 11. Email Notifications

## Status

Deferred

## Priority

Low

---

## Features

- Reminder emails
- Daily summaries
- Weekly reviews

---

# 12. Advanced Analytics

## Status

Partially Deferred

## Priority

Medium

---

## Future Additions

- Productivity heatmaps
- Focus-time analytics
- Completion trends
- Time spent per category
- Long-term performance reports

---

# 13. Attachments Storage Upgrade

## Status

Deferred

## Priority

Medium

---

## Future Features

- Cloud file storage
- PDF previews
- OCR
- Image scanning
- Document extraction

---

# 14. Offline Sync Engine

## Status

Deferred

## Priority

High

---

## Features

- Full offline mode
- Background sync
- Conflict resolution

---

# 15. Wearable Support

## Status

Deferred

## Priority

Low

---

## Platforms

- Android Wear OS
- Apple Watch

---

# 16. ENH-004 — Custom Reminder Audio Playback

## Status

Deferred (Post-v1.0.0 Backlog)

## Priority

Low

---

## Features

- 5-second custom reminder sound playback
- Optional 10-second strong alert
- User-configurable reminder alert intensity (Silent, Standard, Enhanced 5s, Strong 10s)
- Custom audio asset chooser

---

# MVP Boundary (Locked)

The following are NOT required before Play Store launch:

- ❌ AI Assistant
- ❌ AI Goal Breakdown
- ❌ Project Planning System
- ❌ FCM Push Infrastructure
- ❌ Team Collaboration
- ❌ Habit Tracker
- ❌ Calendar Integrations
- ❌ Desktop App
- ❌ Email Notifications
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

---

## Notes

This document should be treated as the official future backlog for Priora.

Whenever a feature is consciously postponed from the MVP roadmap, it should be added here with:

- Purpose
- Reason for Deferral
- Expected Version
- Priority
- Future Requirements

This helps maintain a clean MVP scope while preserving long-term product vision.