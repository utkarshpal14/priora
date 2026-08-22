# Milestone 3 — Deadlines & Priorities

**Status:** Completed  
**Deliverable:** Overdue Detection, Smart Deadline Formatting, 4-Tier Priority System, Composite Ranking Engine, and Smart Urgency Banners.

---

## 1. Scope & Objectives

Milestone 3 equips Priora with intelligent deadline tracking and priority-first scheduling:
- **Automated Overdue Detection:** Any active task whose deadline has passed (`deadline < NOW()`) is dynamically treated as Overdue.
- **Derived State Rule:** `OVERDUE` is strictly a derived runtime calculation and is **never** persisted as a database enum status. Persisted statuses remain `PENDING`, `IN_PROGRESS`, `COMPLETED`, and `CANCELLED`.
- **Composite Ranking:** Deterministic task ordering ensuring high-urgency and overdue items are addressed first.
- **Smart Urgency Banner:** Context-aware banner highlighting overdue obligations and today's schedule at a glance.
- **Timezone Discipline:** All database timestamps stored in UTC; frontend renders localized user timestamps.

---

## 2. Overdue & Due Today Business Rules

### Overdue Condition
A task is marked `is_overdue = true` if:
```text
deadline < NOW(UTC) 
AND status != 'COMPLETED' 
AND status != 'CANCELLED'
AND is_deleted = false
```

### Due Today Condition
A task is marked `is_due_today = true` if:
```text
deadline >= StartOfDay(NOW)
AND deadline < EndOfDay(NOW)
AND status != 'COMPLETED' 
AND status != 'CANCELLED'
AND is_deleted = false
```

---

## 3. Composite Ranking Formula

Tasks in `/api/v1/tasks` are ranked deterministically using a tiered composite algorithm:

```sql
CASE
    -- Tier 1-4: Overdue tasks sorted by priority
    WHEN deadline < NOW() AND status NOT IN ('COMPLETED', 'CANCELLED') AND priority = 'CRITICAL' THEN 1
    WHEN deadline < NOW() AND status NOT IN ('COMPLETED', 'CANCELLED') AND priority = 'HIGH'     THEN 2
    WHEN deadline < NOW() AND status NOT IN ('COMPLETED', 'CANCELLED') AND priority = 'MEDIUM'   THEN 3
    WHEN deadline < NOW() AND status NOT IN ('COMPLETED', 'CANCELLED') AND priority = 'LOW'      THEN 4
    -- Tier 5-8: Standard active tasks sorted by priority
    WHEN priority = 'CRITICAL' THEN 5
    WHEN priority = 'HIGH'     THEN 6
    WHEN priority = 'MEDIUM'   THEN 7
    WHEN priority = 'LOW'      THEN 8
    ELSE 9
END ASC,
deadline ASC NULLS LAST,
created_at DESC
```

---

## 4. API Endpoints & Metrics Contract

### Metrics Structure (`TaskMetrics`)
```json
{
  "total": 25,
  "completed": 10,
  "pending": 15,
  "overdue": 3,
  "due_today": 4
}
```

### Query Filtering
- `GET /api/v1/tasks?status=OVERDUE`: Returns active tasks where `deadline < NOW(UTC)` and `status NOT IN ('COMPLETED', 'CANCELLED')`.
- `GET /api/v1/tasks?priority=CRITICAL`: Filters tasks by specific priority level.

---

## 5. UI & Design Token Specifications

### Priority Color Matrix
| Priority | Color Token | Hex Color | Background Tint |
| :--- | :--- | :--- | :--- |
| **LOW** | Emerald | `#2D6A4F` | `#E8F5E9` |
| **MEDIUM** | Amber | `#D97706` | `#FEF3C7` |
| **HIGH** | Orange | `#EA580C` | `#FFEDD5` |
| **CRITICAL** | Red | `#DC2626` | `#FEE2E2` |

### Relative Deadline Formatting
- **Overdue:** `Overdue (Yesterday • 6:00 PM)` or `Overdue (Aug 15 • 2:30 PM)` in Red `#DC2626`.
- **Due Today:** `Due Today • 6:00 PM` in Amber `#D97706`.
- **Due Tomorrow:** `Tomorrow • 10:00 AM` in Charcoal `#1D1D1D`.
- **Upcoming:** `Aug 28 • 5:00 PM` in Charcoal `#1D1D1D`.

### Smart Banner Hierarchy
1. If `overdue > 0`:  
   `⚠️ {N} overdue task(s) need attention` → Primary action: **View Overdue**
2. Else if `due_today > 0`:  
   `📅 {N} task(s) due today` → Primary action: **View Today**
3. Else:  
   Banner remains hidden.

### Overdue Tab Empty State
- Icon: Celebration / Checkmark
- Headline: `🎉 No overdue tasks`
- Subtext: `You're all caught up!`

---

## 6. Known Limitations & Next Steps

- **Milestone 4 Transition:** Automated notification triggers (FCM / Local alerts) when deadlines approach will be introduced in Milestone 4.
- **Calendar Integration:** Timeline scheduling and drag-and-drop planning will be introduced in Milestone 5 (Planner).
