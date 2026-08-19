# Milestone 6: End-of-Day Review & Rescheduling

## Status
In Progress

## Objective
Implement Priora's **End-of-Day Review & Rescheduling** system. This feature allows users to close out their day by celebrating accomplishments, reflecting on task completion metrics, and effortlessly processing unfinished/overdue work through one-tap rescheduling actions (*Move to Tomorrow*, *Move to Next Week*, *Pick Date*, *Mark Done*, or *Cancel*).

---

## 1. Architectural Principles

1. **Derived Review State (No New DB Tables):**
   - The review session is derived at runtime from tasks and audit timestamps:
     - **Completed Today:** Tasks with `completed_at` falling within target date UTC bounds (`00:00:00` to `23:59:59`).
     - **Incomplete / Rollover Today:** Active tasks due on target date or overdue (`deadline <= end_of_day`) with status `PENDING` or `IN_PROGRESS`.
2. **Batch & Atomic Rescheduling:**
   - Supports resolving incomplete tasks one-by-one or via a single batch request (`POST /api/v1/review/batch-reschedule`).
3. **Action Set:**
   - ➡️ **Tomorrow** (sets deadline to tomorrow at 6:00 PM / preserved time)
   - ⏩ **Next Week** (sets deadline to +7 days from today)
   - 📅 **Pick Date** (custom date selector)
   - ✓ **Mark Done** (sets status to completed)
   - ✕ **Cancel** (sets status to cancelled)
4. **Scope Discipline:**
   - Strictly focused on task resolution. No mood tracking, daily journaling, AI reflection, or productivity scores for MVP.

---

## 2. API Contract

### `GET /api/v1/review/daily?date=YYYY-MM-DD`
Fetch daily review summary.

**Response:**
```json
{
  "success": true,
  "message": "Daily review retrieved successfully.",
  "data": {
    "date": "2026-08-20",
    "completed_tasks": [...],
    "incomplete_tasks": [...],
    "completed_count": 4,
    "incomplete_count": 2,
    "overdue_count": 1,
    "completion_rate": 66.7,
    "total_completed_minutes": 135
  }
}
```

### `POST /api/v1/review/batch-reschedule`
Execute batch resolution actions for incomplete tasks.

**Request:**
```json
{
  "items": [
    {
      "task_id": "uuid-1",
      "action": "MOVE_TOMORROW"
    },
    {
      "task_id": "uuid-2",
      "action": "MOVE_NEXT_WEEK"
    },
    {
      "task_id": "uuid-3",
      "action": "SCHEDULE",
      "new_deadline": "2026-08-23T18:00:00Z"
    },
    {
      "task_id": "uuid-4",
      "action": "COMPLETE"
    },
    {
      "task_id": "uuid-5",
      "action": "CANCEL"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Batch rescheduling completed successfully.",
  "data": {
    "processed_count": 5,
    "updated_tasks": [...]
  }
}
```

---

## 3. UI Workflow & Layout

1. **Accomplishments Recap:**
   - Celebrates completed tasks with completion percentage, pending count, and overdue count.
2. **Interactive Rollover Wizard:**
   - Shows each incomplete task with clear action choices:
     - ➡️ **Tomorrow** (1-tap move to next day)
     - ⏩ **Next Week** (1-tap move to +7 days)
     - 📅 **Pick Date** (custom date selector)
     - ✓ **Mark Done** (resolve as completed)
     - ✕ **Cancel** (cancel task)
3. **Review Celebration Dialog:**
   - Summary card displayed upon completing the review session with motivating feedback.
