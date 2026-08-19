# MASTER_TEST_PLAN.md

# Priora — Master QA Test Plan

Version: 1.0
Status: Living Document
Last Updated: YYYY-MM-DD

---

# 1. Authentication

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

# 2. Categories

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

# 3. Tasks

## Task Creation

- Create task with title only
- Create task with description
- Create task with category
- Create task with deadline
- Create task with priority
- Create task with reminder
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
- Edit reminder
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
- Overdue
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

# 4. Deadlines & Priorities

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

# 5. Reminders

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

# 6. Planner

## Calendar Navigation

- Select day
- Jump to today
- Switch future dates
- Switch past dates

## Daily Plan

- Generate plan for today
- Generate plan for empty day
- Generate plan with overdue tasks
- Generate plan with many tasks

## Smart Focus

- Top 3 tasks calculated correctly
- Overdue tasks prioritized
- Critical tasks prioritized
- Focus card actions work

## Timeline

- Morning bucket
- Afternoon bucket
- Evening bucket
- Flexible bucket

## Weekly Preview

- Correct task counts
- Critical indicators
- Completion counts

---

# 7. Daily Review

## Review Summary

- Completed tasks shown
- Incomplete tasks shown
- Overdue tasks shown
- Completion percentage correct

## Rescheduling

- Move to tomorrow
- Move to next week
- Pick custom date
- Mark done
- Cancel task

## Review Completion

- All tasks processed
- Celebration dialog appears
- Statistics accurate

---

# 8. Future Features

## Long-Term Goals

- Create goal
- Edit goal
- Delete goal

## Goal Breakdown

- Convert goal to milestones
- Convert milestone to tasks
- Track progress

## Weekly Planning

- Generate weekly plan
- Update weekly plan

## Monthly Planning

- Generate monthly plan
- Update monthly plan

---

# 9. Analytics & Dashboard

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

- Metrics update after creation
- Metrics update after completion
- Metrics update after deletion

---

# 10. Offline & Sync

## Offline

- Open app offline
- Create task offline
- Edit task offline
- Complete task offline

## Sync

- Sync after reconnect
- Conflict resolution
- Retry failed requests

---

# 11. Security

## Authorization

- User cannot access another user's tasks
- User cannot access another user's reminders
- User cannot access another user's categories

## Token Security

- Invalid JWT rejected
- Expired JWT rejected
- Refresh token misuse prevented

## API Abuse

- Rate limiting
- Brute force protection
- Malformed payload handling

---

# 12. Performance

## Task Volume

- 100 tasks
- 500 tasks
- 1000 tasks
- 5000 tasks

## Reminder Volume

- 50 reminders
- 100 reminders
- 500 reminders

## Startup

- Cold start
- Warm start
- Session restore

---

# 13. Mobile Device Testing

## Android

- Android 10
- Android 11
- Android 12
- Android 13
- Android 14

## Screen Sizes

- Small phone
- Medium phone
- Large phone
- Tablet

## Orientation

- Portrait
- Landscape

---

# 14. Accessibility

- Screen reader support
- Large text support
- High contrast mode
- Keyboard navigation
- Touch target size

---

# 15. Release Checklist

## Functional

- All automated tests passing
- All manual tests passing
- No blocker bugs
- No critical bugs

## Mobile

- Android notification testing complete
- Background notification testing complete
- Deep link testing complete

## Store Readiness

- Privacy Policy available
- Terms of Service available
- App icon finalized
- Screenshots prepared
- Feature graphic prepared
- Store description finalized
- Versioning finalized

## Production

- Production environment verified
- Database backup verified
- Error monitoring configured
- Analytics configured
- Crash reporting configured