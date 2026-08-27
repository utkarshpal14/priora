# Priora — Product Roadmap & Backlog Matrix

> **Version:** v1.1.2 (Build 3 / Live Released)  
> **Status:** Active Roadmap  

---

## 1. Release Milestone Map

```
┌───────────────────────────────┐
│     Priora v1.0.0 (MVP)       │
│  (COMPLETED & RELEASE READY)  │
│                               │
│ • Planner Home Screen        │
│ • Task Management & Urgency   │
│ • Native Notification Engine  │
│ • UX-003 Live Diagnostics     │
│ • Goals & Sub-Goals           │
│ • Evening Review Routine      │
│ • Analytics & Attachments     │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  Priora v1.1.0/v1.1.2 (Minor) │
│  (COMPLETED & RELEASED)       │
│                               │
│ • ENH-005 6 Custom Sound Chimes│
│ • ENH-006 In-App OTA Updater  │
│ • Native FileProvider Bridge  │
│ • Dynamic Versioning & Checks │
│ • Versioned APK Archive       │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│     Priora v2.0.0 (Major)     │
│       (FUTURE BACKLOG)        │
│                               │
│ • Recurring Tasks Engine      │
│ • Habit Tracker & Streaks     │
│ • FCM Cloud Push Engine       │
│ • Backend Scheduler Queue     │
│ • Google Calendar Integration │
│ • Desktop Native Apps         │
└───────────────────────────────┘
```

---

## 2. Achieved v1.0.0 Scope vs Post-v1 Backlog Matrix

| Feature Module | v1.0.0 Scope | v1.1 Scope | v2.0 Scope | Status |
|---|---|---|---|---|
| **Planner & Time Blocking** | Daily timeline, virtual sessions, overdue alerts | Drag-and-drop timeline reordering | Calendar import overlay | **v1.0.0 Complete** |
| **Notification Engine** | Local exact alarms, heads-up banner, vibration | Custom 5s/10s audio chime chooser (`ENH-004`) | FCM Cloud Push & retry queue | **v1.0.0 Complete** |
| **Diagnostics & Health** | Live `PowerManager` & Exact Alarm checks (`UX-003`) | Auto-fix prompts | Cloud sync diagnostics | **v1.0.0 Complete** |
| **Task Management** | Tasks, categories, priority, deadlines, urgency banner | Recurring task scheduler | Project target hierarchy | **v1.0.0 Complete** |
| **Goal Tracking** | Target dates, sub-goal checklists | Goal milestone reminders | AI goal decomposition | **v1.0.0 Complete** |
| **Habits & Recurrence** | Daily planning & evening review | Habit tracker with streak metrics | AI habit coaching | Deferred to v1.1 |
| **Multi-Platform** | Android Release APK & Web API | Desktop (macOS/Windows) | Wear OS / Apple Watch | **v1.0.0 Complete** |
