# MASTER_TEST_PLAN.md

# Priora — Master QA Test Plan

---

# Authentication

## Registration

- Register with valid email and password
- Register with existing email
- Register with invalid email format
- Register with weak password
- Register with empty fields
- Register with leading/trailing spaces
- Register with very long email
- Register while offline

## Login

- Login with valid credentials
- Login with incorrect password
- Login with non-existing account
- Login with empty fields
- Login with invalid email format
- Login after password change
- Login while offline

## Session Management

- Session persists after app restart
- Session persists after device restart
- Expired access token refreshes correctly
- Invalid refresh token forces logout
- Corrupted token storage handled safely
- Logout clears session
- Logout redirects to login screen

## Route Protection

- Unauthenticated user cannot access protected routes
- Authenticated user can access protected routes
- Direct URL navigation to protected route
- Token expiration while using app

---

# Categories

## Category Creation

- Create category with valid data
- Create category without color
- Create category without icon
- Create duplicate category name
- Create category with long name
- Create category with empty name

## Category Update

- Rename category
- Change category color
- Change category icon
- Update category with invalid values

## Category Deletion

- Delete category
- Delete category containing tasks
- Verify soft delete behavior
- Verify deleted category hidden from UI

---

# Tasks

## Task Creation

- Create task with title only
- Create task with description
- Create task with category
- Create task with deadline
- Create task with priority
- Create task with all fields
- Create task with empty title
- Create task with long title
- Create task with long description

## Task Editing

- Edit title
- Edit description
- Edit category
- Edit deadline
- Edit priority
- Edit multiple fields together
- Save without changes
- Cancel edit

## Task Status

- Mark task complete
- Reopen completed task
- Mark task cancelled
- Move task to in-progress
- Complete already completed task

## Task Deletion

- Delete task
- Delete completed task
- Delete task with reminders
- Verify soft delete
- Verify deleted task hidden

## Task Search

- Search by full title
- Search by partial title
- Search by description
- Search with no results
- Search with special characters

## Task Filtering

### Status

- Pending
- In Progress
- Completed
- Cancelled
- All

### Priority

- Low
- Medium
- High
- Critical

### Category

- Filter by category
- Multiple category switches
- Category + status combination
- Category + priority combination

---

# Deadlines & Priorities

## Deadline Assignment

- Add deadline during creation
- Add deadline during editing
- Remove deadline
- Past deadline entry
- Future deadline entry

## Overdue Detection

- Task becomes overdue automatically
- Completed task not overdue
- Cancelled task not overdue
- Overdue count updates correctly

## Due Today

- Task due today detected correctly
- Due today count updates

## Due Tomorrow

- Task due tomorrow displayed correctly

## Sorting

- Overdue critical first
- Overdue high second
- Overdue medium third
- Overdue low fourth
- Critical before high
- High before medium
- Medium before low
- Nearest deadline first
- No-deadline tasks last

## UI

- Overdue badge visible
- Due today badge visible
- Priority colors correct
- Urgency banner appears
- Empty overdue state appears

---

# Reminders

## Reminder Creation

- Create reminder 15 minutes before
- Create reminder 30 minutes before
- Create reminder 1 hour before
- Create reminder 3 hours before
- Create reminder 1 day before
- Create custom reminder

## Reminder Validation

- Reminder before deadline
- Reminder exactly at deadline
- Reminder after deadline rejected
- Reminder in past rejected
- Reminder without deadline
- Reminder on completed task rejected
- Reminder on cancelled task rejected

## Reminder Limits

- Create 1 reminder
- Create 5 reminders
- Create 6th reminder rejected

## Reminder Update

- Edit reminder time
- Change preset
- Change custom reminder
- Multiple reminder edits

## Reminder Deletion

- Delete reminder manually
- Delete task removes reminder
- Complete task removes reminder
- Cancel task removes reminder

## Local Notifications

- Notification scheduled correctly
- Notification fires on time
- Notification appears when app open
- Notification appears when app backgrounded
- Notification appears when app closed
- Notification sound works
- Notification vibration works
- Notification opens correct task

---

# Daily Planner (Future)

## Plan Generation

- Generate plan for today
- Generate plan with no tasks
- Generate plan with overdue tasks
- Generate plan with many tasks
- Generate plan with deadlines

## Priority Handling

- Critical tasks scheduled first
- Overdue tasks scheduled first
- Deadline tasks prioritized

## Planner Updates

- Regenerate plan after new task
- Regenerate plan after task completion
- Regenerate plan after task deletion

---

# Daily Review & Rescheduling (Future)

## End Of Day Review

- Show incomplete tasks
- Show completed tasks
- Show overdue tasks

## Rescheduling

- Move task to tomorrow
- Move task to custom date
- Keep deadline unchanged
- Change deadline during reschedule

## Review Flow

- Skip review
- Complete review
- Review with no pending tasks

---

# Long-Term Planning (Future)

## Weekly Planning

- Generate weekly plan
- Update weekly plan

## Monthly Planning

- Generate monthly plan
- Update monthly plan

## Goal Breakdown

- Convert goal into tasks
- Convert goal into milestones
- Track goal progress

---

# Attachments

## Upload

- Upload PDF
- Upload Image
- Upload Document
- Upload Multiple Files
- Upload Large File

## Access

- Open attachment
- Download attachment
- Preview attachment

## Deletion

- Delete attachment
- Delete task with attachment

---

# Dashboard & Analytics

## Metrics

- Total tasks
- Completed tasks
- Pending tasks
- Overdue tasks
- Due today tasks

## Charts

- Weekly completion chart
- Monthly completion chart
- Category breakdown
- Priority breakdown

## Accuracy

- Metrics update after task creation
- Metrics update after completion
- Metrics update after deletion

---

# Offline & Sync

## Offline Mode

- Open app offline
- Create task offline
- Edit task offline
- Complete task offline

## Reconnection

- Sync after reconnect
- Resolve conflicts
- Retry failed requests

---

# Security

## Authorization

- User cannot access another user's tasks
- User cannot access another user's reminders
- User cannot modify another user's categories

## Token Security

- Invalid JWT rejected
- Expired JWT rejected
- Refresh token misuse prevented

---

# Performance

## Task Volume

- 100 tasks
- 500 tasks
- 1000 tasks

## Reminder Volume

- 50 reminders
- 100 reminders

## Startup

- Cold start performance
- Session restore performance

---

# Release Checklist

- All automated tests passing
- All manual tests passing
- No critical bugs
- No blocker bugs
- Android notification testing complete
- Production environment verified
- Privacy policy available
- App icon finalized
- Play Store assets prepared