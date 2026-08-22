# Priora — REST API Specification

> **Version:** v1.0.0 (Build 100 / RC1 Approved)  
> **Base URL:** `/api/v1`  
> **Auth Header:** `Authorization: Bearer <JWT_TOKEN>`  

---

## 1. Authentication Endpoints (`/api/v1/auth`)

### `POST /auth/register`
Creates a new user account with email and password.
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePassword123!",
    "full_name": "Utkarsh Pal"
  }
  ```
- **Response `201 Created`:**
  ```json
  {
    "token": "eyJhbGciOiJKV1QiLCJ...",
    "user": {
      "id": "c1f7a08b-...",
      "email": "user@example.com",
      "full_name": "Utkarsh Pal"
    }
  }
  ```

### `POST /auth/login`
Authenticates existing credentials and issues JWT token.

### `POST /auth/google`
Authenticates Google OAuth2 ID Token and returns JWT bearer session.

### `GET /auth/me`
Restores current authenticated user profile.

---

## 2. Tasks Endpoints (`/api/v1/tasks`)

### `GET /tasks`
Retrieves list of tasks for authenticated user.
- **Query Parameters:** `status` (pending, completed, overdue), `category_id`, `search`, `limit`, `offset`.

### `POST /tasks`
Creates a new task.
- **Request Body:**
  ```json
  {
    "title": "Complete Priora v1 Documentation",
    "description": "Consolidate active canonical documentation set",
    "category_id": "8f3b2a...",
    "priority": "high",
    "deadline": "2026-08-23T18:00:00Z",
    "estimated_duration": 60
  }
  ```

### `PUT /tasks/{id}`
Updates existing task details or priority.

### `PATCH /tasks/{id}/complete`
Toggles task completion status.

### `DELETE /tasks/{id}`
Deletes task and cascades attached reminders/sessions.

---

## 3. Hourly Planner Endpoints (`/api/v1/planner`)

### `GET /planner/daily`
Retrieves daily plan summary, calendar metrics, focus tasks, time blocks, and overdue items for a selected date.
- **Query Parameter:** `date` (YYYY-MM-DD format).
- **Response `200 OK`:**
  ```json
  {
    "date": "2026-08-22",
    "focus_tasks": [...],
    "time_blocks": [...],
    "unscheduled_tasks": [...],
    "overdue_tasks": [...],
    "summary": {
      "total": 8,
      "completed": 5,
      "pending": 3
    }
  }
  ```

### `POST /planner/sessions`
Creates an hourly time block (`TaskSession`) scheduled on timeline.

### `PUT /planner/sessions/{id}`
Modifies an existing task session's start time, end time, or notes.

### `DELETE /planner/sessions/{id}`
Removes a time block session from the timeline.

---

## 4. Goals & Sub-Goals (`/api/v1/goals`)

### `GET /goals` — Lists all goals and completion percentages.
### `POST /goals` — Creates a new goal.
### `POST /goals/{id}/subgoals` — Adds a sub-goal checklist item.

---

## 5. Evening Review (`/api/v1/reviews`)

### `GET /reviews/daily` — Fetches reflection entry for specified date.
### `POST /reviews/daily` — Saves completed evening review notes and metrics.

---

## 6. System Diagnostics & Health (`/api/v1/health`)

### `GET /health` — Returns backend health, DB connection status, and API version.
