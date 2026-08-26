# Priora v1.1.0 Database Changes

Version: 1.1.0  
Status: Frozen / Approved (v1.1.0 Baseline)  
Freeze Date: August 25, 2026  
Migration Type: Backward Compatible  

---

# Purpose

This document defines all database modifications required for Priora v1.1.0.

Primary goals:
- Support recurring tasks
- Support recurring reminders
- Preserve compatibility with existing users
- Avoid destructive schema changes

---

# Compatibility Policy

**Mandatory Rule:**  
Existing Priora v1.0.0 installations must continue functioning without any updates.

---

### Allowed Database Operations
- ✓ ADD COLUMN
- ✓ ADD TABLE
- ✓ ADD INDEX
- ✓ ADD CONSTRAINT (when safe)

---

### Forbidden Database Operations
- ✗ DROP COLUMN
- ✗ RENAME COLUMN
- ✗ CHANGE COLUMN TYPE
- ✗ DELETE TABLE
- ✗ BREAK EXISTING RELATIONSHIPS

---

# Existing Tasks Table

Current table remains unchanged.

No existing columns may be removed.

No existing column names may be altered.

---

# New Columns

**Table:** `tasks`

---

## repeat_type

**Purpose:** Defines recurrence frequency.

**Type:** `VARCHAR(20)`

**Default:** `'none'`

**Allowed Values:**
- `none`
- `daily`
- `weekly`
- `monthly`

**Migration:**
```sql
ALTER TABLE tasks
ADD COLUMN repeat_type VARCHAR(20) DEFAULT 'none';
```

---

## repeat_interval

**Purpose:** Allows future custom intervals.

**Examples:**
- `1` = every day
- `2` = every 2 days

**Type:** `INTEGER`

**Default:** `1`

**Migration:**
```sql
ALTER TABLE tasks
ADD COLUMN repeat_interval INTEGER DEFAULT 1;
```

---

## repeat_end_date

**Purpose:** Optional date when recurrence stops.

**Type:** `TIMESTAMP`

**Default:** `NULL`

**Migration:**
```sql
ALTER TABLE tasks
ADD COLUMN repeat_end_date TIMESTAMP NULL;
```

---

# Existing Records

All existing tasks must remain valid.

**Migration Result for Old Tasks:**
- `repeat_type = 'none'`
- `repeat_interval = 1`
- `repeat_end_date = NULL`

*No user action required.*

---

# Reminder Compatibility

- Existing reminders continue operating normally.
- Current reminder logic remains unchanged.
- Recurring reminders will only apply to tasks created using v1.1.0 features.

---

# Future Expansion

Reserved recurrence types:
- `yearly`
- `weekdays`
- `weekends`
- `custom`

*These values are not implemented in v1.1.0.*

---

# Index Considerations

### Optional Performance Index:
```sql
CREATE INDEX idx_tasks_repeat_type
ON tasks(repeat_type);
```

**Purpose:** Faster recurring task queries.

---

# Rollback Strategy

If deployment fails:
- Recurring functionality can be disabled.
- Existing tasks remain unaffected.
- No existing user data is lost.
- No table restoration required.

---

# Data Integrity Rules

- **Rule 1:** `repeat_type` must never be NULL.
- **Rule 2:** `repeat_interval` must be greater than 0.
- **Rule 3:** `repeat_end_date` may be NULL.
- **Rule 4:** Existing task behavior must remain unchanged when `repeat_type='none'`.

---

# Verification Checklist

After migration:
- [x] Existing tasks visible
- [x] Existing reminders work
- [x] Existing users can login
- [x] Existing users can create tasks
- [x] Existing users can complete tasks
- [x] New recurring tasks can be created
- [x] No API regressions
- [x] No database errors

---

# Release Approval Requirement

Database migration is approved only if:
- Existing v1.0.0 APK functions normally
- Existing database records remain intact
- No user data is lost
- Recurring task functionality passes testing

---

*End of Document*
