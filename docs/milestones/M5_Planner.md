# Milestone 5: Daily Planner & Hourly Time-Block Scheduling

## Status
Completed (Upgraded to Hourly Time-Block & Multi-Session Scheduling)

## Objective
Provide an actionable, structured daily execution view. Instead of vague broad buckets, Priora empowers users with **concrete hourly time-blocking and multi-session scheduling** (e.g. *10:00 AM – 12:00 PM: Solve DSA*), current time indicator, conflict detection, and quick scheduling directly from the planner.

---

## 1. Architectural Principles

1. **Deadline vs Scheduled Time Distinction:**
   - **Deadline (`Task.deadline`):** The absolute due date/time when a task must be finished.
   - **Work Session (`TaskSession`):** When the user actually plans to sit down and focus on the task.
2. **Multi-Session Task Architecture:**
   - A single substantial task (e.g., *Complete Striver Arrays*) can be worked on across multiple scheduled sessions:
     - *Session 1:* Monday 10:00 AM – 12:00 PM (120 mins)
     - *Session 2:* Wednesday 6:00 PM – 8:00 PM (120 mins)
     - *Session 3:* Saturday 9:00 AM – 12:00 PM (180 mins)
3. **Automatic Duration Computation:**
   - Duration is derived directly from `(scheduled_end - scheduled_start)` in minutes.
4. **Conflict & Overlap Detection:**
   - Soft overlap detection flags overlapping sessions in the planner UI, highlighting conflicts while giving students full scheduling freedom.
5. **Real-Time Timeline Marker:**
   - Real-time current time indicator displays exact position in the day (e.g., `11:15 AM`).

---

## 2. Data Models

### `TaskSession`
- `id`: UUID (Primary Key)
- `task_id`: UUID (FK to `tasks.id`, ondelete="CASCADE")
- `scheduled_start`: DateTime (with timezone UTC)
- `scheduled_end`: DateTime (with timezone UTC)
- `created_at`, `updated_at`, `is_deleted`

---

## 3. API Contract

### `GET /api/v1/planner/day?date=YYYY-MM-DD`
Fetch comprehensive day plan with hourly time-blocks and unscheduled tasks.

**Response:**
```json
{
  "date": "2026-08-20",
  "time_blocks": [
    {
      "id": "session-uuid-1",
      "task_id": "task-uuid-1",
      "scheduled_start": "2026-08-20T10:00:00Z",
      "scheduled_end": "2026-08-20T12:00:00Z",
      "duration_minutes": 120,
      "formatted_time_range": "10:00 AM – 12:00 PM",
      "has_conflict": false,
      "task": { ... }
    }
  ],
  "unscheduled_tasks": [ ... ],
  "focus_tasks": [ ... ],
  "summary": { ... }
}
```

### `POST /api/v1/planner/sessions`
Create a work session for a task. Validates `scheduled_end > scheduled_start`.

### `PUT /api/v1/planner/sessions/{id}`
Update session time window.

### `DELETE /api/v1/planner/sessions/{id}`
Remove a scheduled work session.
