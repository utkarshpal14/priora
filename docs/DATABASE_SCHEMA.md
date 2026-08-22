# Priora — Database Schema & Data Models

> **Version:** v1.0.0 (Build 100 / RC1 Approved)  
> **Database Engine:** PostgreSQL 15+  
> **ORM:** SQLAlchemy 2.0 (Async)  

---

## 1. Entity Relationship Overview

```
 ┌──────────────┐       1:N       ┌──────────────┐
 │    users     ├────────────────►│  categories  │
 └──────┬───────┘                 └──────┬───────┘
        │                                │ 1:N
        │ 1:N                            ▼
        │                         ┌──────────────┐       1:N       ┌──────────────┐
        ├────────────────────────►│    tasks     ├────────────────►│  reminders   │
        │                         └──────┬───────┘                 └──────────────┘
        │                                │ 1:N
        │ 1:N                            ▼
        ├────────────────────────►│task_sessions │
        │                         └──────────────┘
        │ 1:N                     ┌──────────────┐       1:N       ┌──────────────┐
        ├────────────────────────►│    goals     ├────────────────►│  sub_goals   │
        │                         └──────────────┘                 └──────────────┘
        │ 1:N                     ┌──────────────┐
        ├────────────────────────►│ daily_reviews│
        │                         └──────────────┘
        │ 1:N                     ┌──────────────┐
        └────────────────────────►│ attachments  │
                                  └──────────────┘
```

---

## 2. Table Specifications

### Table 1: `users`
Stores user profile information, authentication credentials, and system timestamps.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | Primary Key, Default UUID4 | Unique user identifier |
| `email` | VARCHAR(255) | Unique, Not Null, Indexed | User email address |
| `password_hash` | VARCHAR(255) | Nullable | Bcrypt hashed password (null for OAuth users) |
| `full_name` | VARCHAR(255) | Nullable | User display name |
| `google_id` | VARCHAR(255) | Unique, Nullable | Google OAuth2 subject ID |
| `is_active` | BOOLEAN | Default TRUE | Account active flag |
| `created_at` | TIMESTAMPTZ | Default NOW() | Record creation timestamp |
| `updated_at` | TIMESTAMPTZ | Default NOW() | Record last update timestamp |

---

### Table 2: `categories`
Organizes tasks into distinct life/work domains.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | Primary Key, Default UUID4 | Category identifier |
| `user_id` | UUID | FK -> `users.id` (CASCADE) | Owner user ID |
| `name` | VARCHAR(100) | Not Null | Category display name (e.g. Work, Study, Health) |
| `color_hex` | VARCHAR(7) | Default '#3B82F6' | Hex color badge |
| `icon` | VARCHAR(50) | Default 'tag' | Icon identifier |
| `created_at` | TIMESTAMPTZ | Default NOW() | Creation timestamp |

---

### Table 3: `tasks`
Core task items with deadlines, priority, and status tracking.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | Primary Key, Default UUID4 | Task identifier |
| `user_id` | UUID | FK -> `users.id` (CASCADE) | Owner user ID |
| `category_id` | UUID | FK -> `categories.id` (SET NULL) | Linked category ID |
| `title` | VARCHAR(255) | Not Null | Task title |
| `description` | TEXT | Nullable | Detailed description / notes |
| `priority` | VARCHAR(20) | Default 'medium' | Priority enum: `low`, `medium`, `high` |
| `status` | VARCHAR(20) | Default 'pending' | Status enum: `pending`, `in_progress`, `completed` |
| `deadline` | TIMESTAMPTZ | Nullable, Indexed | Task target completion deadline |
| `estimated_duration` | INTEGER | Default 30 | Estimated completion time in minutes |
| `goal_id` | UUID | FK -> `goals.id` (SET NULL) | Associated goal ID |
| `completed_at` | TIMESTAMPTZ | Nullable | Completion timestamp |
| `created_at` | TIMESTAMPTZ | Default NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | Default NOW() | Last update timestamp |

---

### Table 4: `reminders`
Scheduled notification alerts attached to tasks.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | Primary Key, Default UUID4 | Reminder identifier |
| `task_id` | UUID | FK -> `tasks.id` (CASCADE) | Associated task ID |
| `remind_at` | TIMESTAMPTZ | Not Null, Indexed | Scheduled trigger time |
| `preset` | VARCHAR(50) | Default '15_min_before' | Offset preset identifier |
| `status` | VARCHAR(20) | Default 'scheduled' | Status: `scheduled`, `triggered`, `cancelled` |
| `created_at` | TIMESTAMPTZ | Default NOW() | Creation timestamp |

---

### Table 5: `task_sessions`
Hourly time-blocking planner sessions attached to tasks.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | Primary Key, Default UUID4 | Time block session identifier |
| `task_id` | UUID | FK -> `tasks.id` (CASCADE) | Target task ID |
| `user_id` | UUID | FK -> `users.id` (CASCADE) | Owner user ID |
| `start_time` | TIMESTAMPTZ | Not Null, Indexed | Scheduled session start time |
| `end_time` | TIMESTAMPTZ | Not Null | Scheduled session end time |
| `status` | VARCHAR(20) | Default 'planned' | Session status: `planned`, `active`, `completed` |
| `notes` | TEXT | Nullable | Focus session reflection notes |

---

### Table 6: `goals` & `sub_goals`
Tracks macro objectives and sub-goal checklists.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | Primary Key | Goal identifier |
| `user_id` | UUID | FK -> `users.id` | Owner user ID |
| `title` | VARCHAR(255) | Not Null | Goal title |
| `target_date` | TIMESTAMPTZ | Nullable | Goal target date |
| `status` | VARCHAR(20) | Default 'active' | Goal status |

---

### Table 7: `daily_reviews`
End-of-day reflection entries.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | Primary Key | Review entry ID |
| `user_id` | UUID | FK -> `users.id` | Owner user ID |
| `review_date` | DATE | Not Null | Review date |
| `notes` | TEXT | Nullable | Reflection notes |
| `completion_rate` | FLOAT | Default 0.0 | Daily completion percentage |
