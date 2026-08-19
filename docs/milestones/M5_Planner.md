# Milestone 5 — Planner (Daily Planner & Timeline Scheduling)

## 1. Overview & Purpose
The **Planner** transforms Priora from a passive task storage manager into an active execution engine. It provides a structured daily timeline and weekly lookahead, answering the essential question: *"What should I do today, and how is my time allocated across the day and week?"*

---

## 2. Core Architecture Invariants

1. **Derived System / No Synchronized Shadow Tables**:
   - The planner is generated dynamically from the active `Task` collection (`deadline`, `priority`, `status`, `category`, `estimated_minutes`).
   - No separate planner tables or synchronization workers are needed.

2. **Lightweight Task Duration (`estimated_minutes`)**:
   - Tasks support an optional duration in minutes (e.g. `15`, `30`, `60`, `120`).
   - Used for displaying duration badges and calculating total daily workload.

3. **Composite Ranking for Top 3 Smart Focus**:
   - Top 3 focus tasks for the day are computed using composite urgency scoring:
     1. `Overdue + Critical`
     2. `Overdue + High`
     3. `Overdue + Medium`
     4. `Overdue + Low`
     5. `Critical`
     6. `High`
     7. `Medium`
     8. `Low`
   - Nearest deadline acts as the tie-breaker within the same priority level.

4. **Timeline Buckets**:
   - Tasks for a selected date are bucketed into:
     - **Morning** (`deadline` time < 12:00 PM)
     - **Afternoon** (`deadline` time between 12:00 PM and 5:00 PM)
     - **Evening** (`deadline` time >= 5:00 PM)
     - **Flexible / Anytime** (no time specified or unscheduled on that date)

5. **Actionable User Flow**:
   - Focus items and timeline tasks allow direct actions: `Mark Complete`, `Start / In-Progress`, `Move to Today`, and tap to open edit sheet.

---

## 3. API Endpoints

### 1. Daily Plan
`GET /api/v1/planner/day?date=YYYY-MM-DD`
- **Response**:
  ```json
  {
    "success": true,
    "data": {
      "date": "2026-08-20",
      "summary": {
        "total": 5,
        "completed": 2,
        "pending": 3,
        "overdue_count": 1,
        "completion_percentage": 40.0
      },
      "overdue_tasks": [...],
      "focus_tasks": [...],
      "timeline": [
        { "name": "Morning", "tasks": [...] },
        { "name": "Afternoon", "tasks": [...] },
        { "name": "Evening", "tasks": [...] },
        { "name": "Anytime", "tasks": [...] }
      ]
    }
  }
  ```

### 2. Weekly Plan
`GET /api/v1/planner/week?start_date=YYYY-MM-DD`
- **Response**:
  ```json
  {
    "success": true,
    "data": {
      "start_date": "2026-08-17",
      "end_date": "2026-08-23",
      "total_tasks": 15,
      "completed_tasks": 6,
      "days": [
        {
          "date": "2026-08-20",
          "day_name": "Thursday",
          "task_count": 5,
          "due_count": 4,
          "completed_count": 2,
          "overdue_count": 1,
          "has_critical": true
        }
      ]
    }
  }
  ```

### 3. Move to Today
`POST /api/v1/planner/move-to-today`
- **Request**: `{ "task_id": "uuid" }`
- **Action**: Sets the task's deadline to today (preserving time or setting to end of day).

### 4. Schedule Task
`POST /api/v1/planner/schedule`
- **Request**: `{ "task_id": "uuid", "deadline": "2026-08-21T18:00:00Z" }`
- **Action**: Updates the task's deadline.

---

## 4. Screen Layout Order (Planner)

1. 📅 **Calendar Strip** (horizontal day selector with active task indicators)
2. 📊 **Progress Summary** (completion percentage & count)
3. 🔥 **Overdue Alert** (urgent callout when overdue tasks exist)
4. 🎯 **Top 3 Smart Focus** (actionable priority cards)
5. ⏰ **Timeline Schedule** (Morning, Afternoon, Evening, Flexible)
6. 🗓️ **Weekly Preview** (7-day lookahead cards with `due_count`)
