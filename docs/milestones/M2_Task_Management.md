# Milestone 2 — Task Management (Core)

**Status:** Completed (Milestone 2.1 Refinement)  
**Deliverable:** Full Task CRUD, Priority-First Ordering, Soft Deletion, Category Filtering, and Fast Bottom-Sheet Editing.

---

## 1. Scope & Objective

Milestone 2 establishes the core task management engine for Priora:
- **Task Lifecycle:** Creation, retrieval, editing, completion, reopening, and soft deletion.
- **Organization:** Category taxonomy, priority levels (Low, Medium, High, Critical), and deadline assignment.
- **Search & Filtering:** Text search across title/description, status tabs (Pending, Completed, All), priority pills, and category dropdown filtering.
- **Performance & UX:** Optimistic updates, modal bottom-sheet editors (Things 3 / TickTick style), and read-only metadata inspection.

---

## 2. API Endpoints Contract

All endpoints require JWT Bearer authentication (`Authorization: Bearer <token>`).

| Method | Endpoint | Description | Request Body | Response Data |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/tasks` | List tasks with filters (`status`, `priority`, `category_id`, `search`, `limit`) | None | `{ tasks: [...], metrics: { total, completed, pending } }` |
| `POST` | `/api/v1/tasks` | Create a new task | `{ title, description?, priority?, category_id?, deadline? }` | `Task` |
| `GET` | `/api/v1/tasks/{id}` | Get single task details | None | `Task` |
| `PUT` | `/api/v1/tasks/{id}` | Update task properties | `{ title?, description?, priority?, status?, category_id?, deadline? }` | `Task` |
| `PATCH` | `/api/v1/tasks/{id}/complete` | Mark task completed (`completed_at = NOW()`) | None | `Task` |
| `PATCH` | `/api/v1/tasks/{id}/reopen` | Reopen completed task (`completed_at = NULL`) | None | `Task` |
| `DELETE` | `/api/v1/tasks/{id}` | Soft delete task (`is_deleted = true`) | None | `null` |
| `GET` | `/api/v1/categories` | List user categories (auto-seeds defaults if empty) | None | `[ Category, ... ]` |
| `POST` | `/api/v1/categories` | Create custom category | `{ name, color?, icon? }` | `Category` |
| `PUT` | `/api/v1/categories/{id}` | Update category | `{ name?, color?, icon? }` | `Category` |
| `DELETE` | `/api/v1/categories/{id}` | Delete category | None | `null` |

---

## 3. Data Models

### Database Schema (`tasks` table)
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NULL REFERENCES categories(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM', -- LOW, MEDIUM, HIGH, CRITICAL
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING, IN_PROGRESS, COMPLETED, CANCELLED
    deadline TIMESTAMP WITH TIME ZONE NULL,
    completed_at TIMESTAMP WITH TIME ZONE NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tasks_user_active ON tasks(user_id, is_deleted);
CREATE INDEX idx_tasks_deadline ON tasks(deadline);
```

### Soft Deletion Rule (DB-003)
Tasks are never permanently deleted from the database via `DELETE FROM tasks`. All delete operations set `is_deleted = TRUE` and all reads enforce `is_deleted = FALSE`.

---

## 4. State Management (Flutter Riverpod)

- **`TasksController` (`StateNotifier<TasksState>`):**
  - Manages loaded task list, categories, metrics, active filters, and loading/error states.
  - Performs **optimistic UI updates** for completion toggles, edits, and deletions with automatic rollback on network failure.
  - Exposes `createTask`, `updateTask`, `deleteTask`, `toggleTaskCompletion`, `setTabFilter`, `setPriorityFilter`, `setCategoryFilter`, and `setSearchQuery`.

---

## 5. UI/UX Decisions

1. **Modal Bottom Sheets for Creation & Editing:** Fast, lightweight overlay sheets rather than disruptive full-screen page transitions.
2. **Read-Only Metadata:** The edit bottom sheet displays `Created At` (e.g., `Created Aug 20, 2026, 9:45 PM`) to give users temporal context without cluttering the main task card.
3. **Scalable Category Filter:** Uses a clean Category Dropdown menu above or beside priority filters to support user categories (e.g., Study, Work, Personal, Health, College, Placement Prep) without overflowing screen width.
4. **Minimalist Aesthetic:** Deep Charcoal (`#1D1D1D`), Muted Emerald (`#2D6A4F`), Warm Ivory background (`#F8F6F2`), and subtle micro-shadows.

---

## 6. Known Limitations & Next Steps

- **Milestone 3 Transition:** Overdue visual badges, smart deadline grouping (Today, Tomorrow, Upcoming), and countdowns will be introduced in Milestone 3.
- **Recurring Tasks:** Recurring schedule generation will be introduced in Milestone 5 (Planner).
