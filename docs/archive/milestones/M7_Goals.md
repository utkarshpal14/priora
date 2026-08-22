# Milestone 7: Goals & Milestones Progress Tracking

## Status
Completed

## Objective
Implement Priora's **Goals & Milestones** system. This allows users to set high-level objectives, decompose them into progressive milestones with contextual descriptions, link daily tasks to them, track dynamic progress, and schedule dedicated task work sessions across the weekly planner with zero AI complexity.

---

## 1. Architectural Principles

1. **3-Tier Execution Hierarchy:**
   - `Goal`: High-level ambition (e.g. *Placement Prep 2026*, *Master Flutter*, *Fitness Target*).
   - `GoalMilestone`: Intermediate target/checkpoint with optional `description` (e.g. *Phase 1: DSA Foundations - Complete all arrays & strings problems from Striver A2Z*).
   - `Task`: Actionable project component linked to a `Goal` (`Task.goal_id`) and `GoalMilestone` (`Task.milestone_id`).
   - `TaskSession`: Concrete hourly focus blocks (e.g., *Mon 10 AM – 12 PM*, *Wed 6 PM – 8 PM*) allowing multi-session execution of long-term tasks.
2. **Dynamic Progress Computation:**
   - The completion percentage of a Goal is computed as:
     $$\text{Progress} = \frac{\text{Completed Milestones} + \text{Completed Linked Tasks}}{\text{Total Milestones} + \text{Total Linked Tasks}} \times 100\%$$
   - When all milestones and linked tasks are completed, the goal automatically transitions to `COMPLETED`.
3. **Recent Activity (Derived):**
   - Derived at query time from `completed_at` timestamps of linked tasks and `updated_at` of completed milestones. No extra table needed.
4. **Strict Manual Control:**
   - No automated AI breakdown. Users maintain full control over goal roadmaps and templates.

---

## 2. Data Models

### `Goal`
- `id`: UUID (Primary Key)
- `user_id`: UUID (FK to users.id)
- `category_id`: UUID | None (FK to categories.id)
- `title`: String (1–255 chars)
- `description`: String | None
- `target_date`: Date | None
- `status`: String (`IN_PROGRESS`, `COMPLETED`, `PAUSED`, `ARCHIVED`)
- `color`: String | None (Default `#6366F1`)
- `icon`: String | None (Default `target`)
- `created_at`, `updated_at`, `is_deleted`

### `GoalMilestone`
- `id`: UUID (Primary Key)
- `goal_id`: UUID (FK to goals.id, ondelete CASCADE)
- `title`: String (1–255 chars)
- `description`: String | None
- `target_date`: Date | None
- `is_completed`: Boolean (Default `False`)
- `order_index`: Integer (Default `0`)
- `created_at`, `updated_at`, `is_deleted`

### `Task` & `TaskSession`
- `Task.goal_id`: UUID | None (FK to goals.id)
- `Task.milestone_id`: UUID | None (FK to goal_milestones.id)
- `Task.sessions`: 1-to-Many relationship with `TaskSession`
