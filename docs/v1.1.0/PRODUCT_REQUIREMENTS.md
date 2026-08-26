# Priora v1.1.0 Product Requirements Document (PRD)

Version: 1.1.0  
Status: Frozen / Approved (v1.1.0 Baseline)  
Freeze Date: August 25, 2026  
Release Type: Minor Feature & UX Enhancement Release  
Compatibility Target: Fully Backward Compatible with v1.0.0  
Author: Priora Team  

---

# 1. Overview

Priora v1.1.0 focuses on improving user experience, reminder effectiveness, theme consistency, and recurring productivity workflows while maintaining full compatibility with existing v1.0.0 users.

This release must not disrupt any currently installed beta APKs or existing backend functionality.

---

# 2. Release Goals

## Primary Goals

- Improve reminder visibility and effectiveness.
- Fix theme application inconsistencies.
- Improve onboarding professionalism.
- Introduce recurring productivity workflows.
- Maintain 100% backward compatibility.

## Non-Goals

The following are explicitly excluded from v1.1.0:

- AI scheduling
- Calendar synchronization
- Team collaboration
- Web application
- Desktop application
- Push notification infrastructure migration
- Major database redesign

---

# 3. Compatibility Requirements

## Mandatory Requirement

All existing v1.0.0 users must continue operating normally after backend deployment.

### Existing APK Compatibility

The following must never break:

- User authentication
- User registration
- Task creation
- Reminder scheduling
- Goal management
- Category management
- Planner functionality
- Notification delivery

### Database Compatibility

Allowed:

- Add new columns
- Add new tables
- Add indexes

Forbidden:

- Remove existing columns
- Rename existing columns
- Modify existing API contracts

---

# 4. Features

---

# BUG-001: Global Theme Synchronization

## Problem

Currently changing the theme from Settings only updates the Settings page.

The rest of the application remains unchanged.

This creates inconsistent UI behavior.

## Objective

Theme selection must apply globally across the entire application.

## Functional Requirements

When a user changes:

Settings → Theme

The following must update immediately:

- Dashboard
- Planner
- Tasks
- Goals
- Settings
- Navigation Shell
- Dialogs
- Bottom Sheets
- App Bars
- Cards

## Acceptance Criteria

- Theme updates without restarting the app.
- Theme persists after application restart.
- Theme remains synchronized across all screens.

**Priority:** Critical

---

# UX-004: Signup Placeholder Cleanup

## Problem

The signup screen currently contains development placeholder values.

Example:

`Utkarsh Pal`

This appears unprofessional to end users.

## Objective

Replace personal placeholders with production-ready text.

## Requirements

Replace with:

- `Enter your full name`

or

- `Your Name`

## Acceptance Criteria

No personal names appear anywhere in onboarding or authentication flows.

**Priority:** Critical

---

# ENH-004: Enhanced Reminder Audio Alerts

## Problem

Users may miss important reminders due to short default notification sounds.

## Objective

Increase reminder awareness without becoming intrusive.

## Functional Requirements

When a reminder notification triggers:

- Notification appears normally.
- Priora custom alert sound plays.
- Audio duration approximately 3–5 seconds.
- Audio stops automatically.
- User can tap notification immediately.
- Reminder scheduling system remains unchanged.

## Non-Functional Requirements

Must not:

- Loop continuously
- Behave like an alarm clock
- Require manual dismissal

## Acceptance Criteria

- Reminder sound plays successfully.
- Audio automatically stops.
- Existing reminders continue functioning.

**Priority:** High

---

# ENH-005: Recurring Tasks

## Problem

Users repeatedly create the same tasks manually.

Examples:

Students:
- Daily DSA Practice
- Daily Study Session
- Weekly Assignment Review

Professionals:
- Daily Standup
- Weekly Reports
- Monthly Reviews

## Objective

Allow tasks to repeat automatically.

## Functional Requirements

Task Creation Screen shall support:

Repeat:

- `Never`
- `Daily`
- `Weekly`
- `Monthly`

Optional:

- Custom Interval (Future Expansion)

## Reminder Support

Recurring tasks must support reminders.

Examples:

Daily:  
Study DSA  
7:00 PM  

Weekly:  
Project Review  
Monday 8:00 PM  

Monthly:  
Pay Credit Card Bill  
1st Day of Month  

## Task Completion Behavior

Completing a recurring task:

- Marks current occurrence completed.
- Automatically schedules next occurrence.

## Acceptance Criteria

Users no longer need to manually recreate recurring tasks.

**Priority:** High

---

# ENH-006: Recurring Reminder Scheduling

## Objective

Enable reminders to repeat automatically with recurring tasks.

## Requirements

Reminder recurrence options:

- `Daily`
- `Weekly`
- `Monthly`

Reminder schedule must remain synchronized with task recurrence.

## Acceptance Criteria

Recurring reminders continue generating future reminders automatically.

**Priority:** High

---

# 5. User Impact

## Existing Users

**Impact:** None  
Existing APK users should continue operating normally.  
No action required.

## New Users

Benefit from:

- Better reminders
- Improved onboarding
- Global themes
- Recurring task workflows

---

# 6. Technical Constraints

- Backend deployments must remain backward compatible.
- No destructive database migrations allowed.
- Existing API responses must remain valid.
- All new fields must be optional.

---

# 7. Success Metrics

The release will be considered successful when:

- Theme synchronization works globally.
- Reminder sound is reliably noticeable.
- Recurring tasks operate correctly.
- Existing v1.0.0 APK users remain unaffected.
- No authentication regressions occur.
- No notification regressions occur.

---

# 8. Release Strategy

- **Phase 1:** Database additions.
- **Phase 2:** Backend compatibility deployment.
- **Phase 3:** Internal testing.
- **Phase 4:** v1.1.0 APK generation.
- **Phase 5:** Beta distribution.
- **Phase 6:** Feedback collection.

---

*End of Document*
