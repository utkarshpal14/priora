# Priora v1.1.0 Technical Specifications

Version: 1.1.0  
Status: Frozen / Approved (v1.1.0 Baseline)  
Freeze Date: August 25, 2026  
Compatibility Target: 100% Backward Compatible with v1.0.0  

---

# Architecture Principles

All v1.1.0 changes must preserve functionality for existing v1.0.0 APK users.

### Allowed:
- Add new database columns
- Add new API fields
- Add new endpoints
- Add new frontend screens

### Forbidden:
- Remove columns
- Rename columns
- Change response contracts
- Break existing endpoints

---

# TS-001 Global Theme Synchronization

## Current Problem
Theme changes only affect Settings screen.

## Target Architecture
Theme state must become a global application state.

**Current:**
Settings Screen Theme State

**Target:**
```
App Theme Provider
├── Dashboard
├── Planner
├── Tasks
├── Goals
├── Settings
└── Navigation Shell
```

## Riverpod Requirements
Create:
- `ThemeNotifier`
- `ThemeRepository`
- `ThemePreferencesService`

Persist:
- Light
- Dark
- System

using `SharedPreferences`.

## Acceptance Criteria
- Theme updates entire app immediately.
- Theme survives restart.
- Theme survives logout/login.

---

# TS-002 Enhanced Reminder Audio

## Objective
Play a custom notification sound when reminders fire.

## Notification Behaviour

```
Reminder Triggered
        ↓
Notification Displayed
        ↓
Custom Priora Sound Plays
        ↓
Auto Stop after 3–5 Seconds
```

## Requirements

### Sound:
- `.mp3` or `.wav`
- bundled with application

### Duration:
- 3–5 seconds

### Must Not:
- Loop infinitely
- Behave as alarm clock
- Require dismissal

## Android Implementation

**Notification Channel:**  
Priora Reminders

**Custom Sound:**  
`res/raw/priora_reminder.mp3`

## Acceptance Criteria
- Reminder remains visible.
- Audio automatically stops.

---

# TS-003 Recurring Tasks

## Objective
Support repeating tasks.

## Supported Frequencies
- None
- Daily
- Weekly
- Monthly

**Future:**
- Custom

---

# Database Changes

**Table:**  
`tasks`

**Add Columns:**
- `repeat_type`
- `repeat_interval`
- `repeat_end_date`

**Schema:**
```sql
ALTER TABLE tasks ADD COLUMN repeat_type VARCHAR(20) DEFAULT 'none';
ALTER TABLE tasks ADD COLUMN repeat_interval INTEGER DEFAULT 1;
ALTER TABLE tasks ADD COLUMN repeat_end_date TIMESTAMP NULL;
```

## Compatibility
- All new columns must be nullable or have safe defaults.
- Existing rows must remain valid.

---

# Task Lifecycle

### Example:

**Task:**  
DSA Practice  

**Repeat:**  
Daily  

**Reminder:**  
7 PM  

---

#### Day 1
```
Task Created
     ↓
Reminder Sent
     ↓
Task Completed
     ↓
Next Occurrence Generated
```

---

#### Day 2
```
Task Visible Again
     ↓
Reminder Sent
     ↓
Completion
     ↓
Next Occurrence Generated
```

---

# Recurring Task Engine

When task marked completed:

`IF repeat_type != none`  
Generate next occurrence.

### Rules:
- **Daily:** `+1 Day`
- **Weekly:** `+7 Days`
- **Monthly:** `+1 Month`

---

# API Changes

All additions must be optional.

**Current Response:**
```json
{
  "title": "DSA Practice"
}
```

**Future Response:**
```json
{
  "title": "DSA Practice",
  "repeat_type": "daily",
  "repeat_interval": 1
}
```

Existing clients ignore new fields.

---

# TS-004 Recurring Reminders

Reminder schedule must follow task schedule.

### Examples:
- **Daily:** 7 PM
- **Weekly:** Monday 8 PM
- **Monthly:** 1st Day 9 AM

When next task occurrence generated:  
*Generate next reminder automatically.*

---

# TS-005 Data Migration Strategy

**Migration Type:** Non-Destructive

### Allowed:
- `ALTER TABLE ADD COLUMN`

### Forbidden:
- `DROP COLUMN`
- `ALTER COLUMN TYPE`
- `RENAME COLUMN`

---

# TS-006 Compatibility Verification

### Environment A
**v1.0.0 APK + v1.1.0 Backend**  
*Expected:* Fully Functional

---

### Environment B
**v1.1.0 APK + v1.1.0 Backend**  
*Expected:* All New Features Functional

---

### Environment C
**Mixed Users**  
*Expected:* No Regression

---

# Release Gate

v1.1.0 cannot release unless:

- [x] Existing APK functions
- [x] Login works
- [x] Registration works
- [x] Notifications work
- [x] Theme works globally
- [x] Recurring tasks work
- [x] Reminder audio works

---

# TS-007 Release Build Stability Fix

### Issue
Notifications and custom reminder sounds worked in debug mode (`flutter run`) but failed in release APKs (`flutter build apk --release`).

### Root Cause
Android release optimization removed required resources (`.wav` audio assets in `res/raw`) and stripped notification-related classes.

### Resolution
Disabled minification and resource shrinking in `android/app/build.gradle.kts`:
- `isMinifyEnabled = false`
- `isShrinkResources = false`

### Result
- Reminder delivery restored
- Sound previews restored
- Custom notification sounds restored
- Release APK verified on Android 13 device

---

*End of Document*
