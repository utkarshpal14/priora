# Priora v1.1.0 — Technical Specifications & Backlog Scope

> **Target Version:** v1.1.0 (Minor Release)  
> **Status:** Planned / Under Design  

---

## 1. Overview

Priora v1.1.0 builds upon the stable v1.0.0 foundation, introducing user-requested audio customizations, recurring task automation, and habit tracking.

---

## 2. Planned Features & Scope

### ENH-004 — Custom Reminder Audio Playback & Intensity
- **5-Second Custom Audio Chimes:** User selectable notification sound assets (`priora_alert.wav`, `chime_soft.wav`, `alert_chime.wav`).
- **10-Second Strong Alerts:** Extended alert option for high-priority deadline notifications.
- **Alert Intensity Presets:** User setting options:
  - `Silent`
  - `Standard System Sound`
  - `Enhanced Alert (5s)`
  - `Strong Alert (10s)`

### Recurring Tasks Engine
- **Recurrence Frequencies:** Daily, Weekly, Monthly, and Custom intervals.
- **Auto-Generation:** Automatic instantiation of task instances upon completion or arrival of next scheduled date.

### Habit Tracker & Streaks
- **Habit Checklists:** Daily habits (e.g. DSA Practice, Exercise, Meditation).
- **Productivity Streaks:** Visual streak counters and monthly consistency percentage heatmaps.
