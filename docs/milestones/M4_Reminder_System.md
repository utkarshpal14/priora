# Milestone 4 — Reminder System

---

## 1. Overview & Scope

Milestone 4 introduces reliable task reminders and on-device notifications to Priora. Designed with an MVP-first architecture, the system combines clean server-side Reminder management and strict deadline validation with client-side local notifications, avoiding the premature complexity of cloud push gateways (FCM/APNs) and background server polling loops until production release.

---

## 2. Core Business Rules

1. **Derived Ownership:** `Reminder` does not store `user_id`; user ownership is strictly derived via the associated `Task` (`Reminder.task_id → Task.id → Task.user_id`).
2. **Pre-Deadline Constraint (SRS Rule):** A reminder cannot be scheduled after the task's deadline:
   $$\text{remind\_at} \le \text{task.deadline}$$
3. **Future Timestamp Rule:** All new reminders must be set for a future timestamp:
   $$\text{remind\_at} > \text{NOW(UTC)}$$
4. **Per-Task Limit:** A maximum of **5 active reminders** can be attached to a single task (e.g., 1 day before, 3 hours before, 1 hour before, 30 min before, 15 min before).
5. **Auto-Cancellation on Task Lifecycle:**
   When a task status transitions to `COMPLETED` or `CANCELLED`, or when a task is soft-deleted:
   - All associated `SCHEDULED` reminders on the server are automatically updated to `CANCELLED`.
   - The client immediately invokes `cancelTaskNotifications(taskId)` to remove scheduled alarms from the device.
6. **Timezone Protocol:** Backend stores and validates `remind_at` strictly in UTC. Frontend calculates relative presets and displays formatted times in the user's local device timezone.
7. **Web Platform Note:** Local notifications are natively supported on Android and iOS. On Flutter Web, notifications depend on browser permission state and active tab/worker lifecycles.

---

## 3. Database Schema

### Table: `reminders`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY` | Unique reminder ID |
| `task_id` | `UUID` | `FOREIGN KEY (tasks.id) ON DELETE CASCADE, INDEXED` | Associated task |
| `notification_id` | `INTEGER` | `NULLABLE, INDEXED` | Integer ID used for device alarm cancellation |
| `remind_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL, INDEXED` | Scheduled notification time (UTC) |
| `status` | `VARCHAR(20)` | `NOT NULL, DEFAULT 'SCHEDULED', INDEXED` | `SCHEDULED`, `SENT`, `CANCELLED` |
| `is_deleted` | `BOOLEAN` | `NOT NULL, DEFAULT FALSE` | Soft delete flag |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL` | Creation timestamp |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL` | Last update timestamp |

---

## 4. API Specification

| Method | Endpoint | Description | Status Codes |
|---|---|---|---|
| `POST` | `/api/v1/reminders` | Create reminder for a task (validates limit $\le 5$, $\le$ deadline, $>$ now) | `201 Created`, `400 Bad Request`, `404 Not Found` |
| `GET` | `/api/v1/reminders` | List user's reminders (query filter by `task_id`, `status`) | `200 OK` |
| `GET` | `/api/v1/reminders/{id}` | Get single reminder details | `200 OK`, `404 Not Found` |
| `PUT` | `/api/v1/reminders/{id}` | Update reminder timestamp or status | `200 OK`, `400 Bad Request`, `404 Not Found` |
| `DELETE` | `/api/v1/reminders/{id}` | Soft delete / cancel reminder | `200 OK`, `404 Not Found` |

---

## 5. Reminder Presets (Frontend)

| Preset | Relative Offset from Deadline |
|---|---|
| `15m` | $\text{deadline} - 15 \text{ minutes}$ |
| `30m` | $\text{deadline} - 30 \text{ minutes}$ |
| `1h` | $\text{deadline} - 1 \text{ hour}$ |
| `3h` | $\text{deadline} - 3 \text{ hours}$ |
| `1d` | $\text{deadline} - 24 \text{ hours}$ |
| `Custom` | User-selected specific Date & Time ($\le \text{deadline}$) |

---

## 6. Future Roadmap Notes (Milestone 5+)
- **Postpone / "Remind me tomorrow":** To be integrated into the Daily Planner and End-of-Day Review workflows.
- **Push Notification Infrastructure (FCM/APNs):** Cloud push infrastructure, device token registration, and background workers deferred until release preparation milestone.
