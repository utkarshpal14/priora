# Priora v1.1.0 Migration Plan

Version: 1.1.0  
Status: Frozen / Approved (v1.1.0 Baseline)  
Freeze Date: August 25, 2026  
Migration Type: Zero-Downtime / Backward Compatible  

---

# Objective

Deploy Priora v1.1.0 features while ensuring:
- Existing v1.0.0 APK users remain fully functional.
- No service interruption occurs.
- No data loss occurs.
- No API contracts break.

---

# Existing Production Environment

- **Frontend:** Priora v1.0.0 APK
- **Backend:** FastAPI
- **Database:** Supabase PostgreSQL
- **Hosting:** Render
- **Current Users:** Beta Testers (8–10 users)

---

# Deployment Principles

- **Rule 1:** Never deploy breaking database changes.
- **Rule 2:** Never deploy breaking API changes.
- **Rule 3:** Backend must support both `v1.0.0 APK` and `v1.1.0 APK` simultaneously.
- **Rule 4:** Existing users must not be forced to update.

---

# Phase 1: Development

**Status:** Local Environment Only  

### Changes Allowed:
- ✓ Theme Fix
- ✓ Signup Placeholder Fix
- ✓ Reminder Audio Support
- ✓ Recurring Tasks
- ✓ Recurring Reminders

*No production impact.*

---

# Phase 2: Database Preparation

**Goal:** Add support for recurring tasks.

### Migration Script
```sql
ALTER TABLE tasks
ADD COLUMN repeat_type VARCHAR(20) DEFAULT 'none';

ALTER TABLE tasks
ADD COLUMN repeat_interval INTEGER DEFAULT 1;

ALTER TABLE tasks
ADD COLUMN repeat_end_date TIMESTAMP NULL;
```

### Expected Result
- Existing tasks remain unchanged.
- Existing users unaffected.
- No API changes required.

### Verification
- [x] Existing tasks visible
- [x] Existing reminders visible
- [x] Existing users login successfully

---

# Phase 3: Backend Upgrade

**Goal:** Add recurring task support.

### Requirements
Backend must continue accepting old requests.

**Old Request (Must still work):**
```json
{
  "title": "Study DSA"
}
```

**New Request (Must also work):**
```json
{
  "title": "Study DSA",
  "repeat_type": "daily",
  "repeat_interval": 1
}
```

### Verification
- [x] Login works
- [x] Registration works
- [x] Existing task creation works
- [x] Existing reminder creation works
- [x] Health endpoint works

---

# Phase 4: Compatibility Testing

### Environment A
**v1.0.0 APK + New Backend**  
*Expected:* 100% Functional

### Environment B
**Development APK + New Backend**  
*Expected:* 100% Functional

### Environment C
**Mixed User Environment**  
*Expected:* No regressions

### Checklist
- [x] Authentication
- [x] Tasks
- [x] Goals
- [x] Categories
- [x] Planner
- [x] Notifications
- [x] Reminders

---

# Phase 5: Production Backend Deployment

- **Deploy:** Render Backend
- **Database:** Already migrated.
- **Expected Downtime:** 0 Minutes

### Verification
`GET /api/v1/health` returns:
```json
{
  "success": true
}
```

Verify:
- [x] Login
- [x] Registration
- [x] Task CRUD
- [x] Reminder CRUD
- [x] Existing APK users operational

---

# Phase 6: Internal Validation

- **Tester:** Project Owner
- **Duration:** 24–48 Hours

### Tasks:
- [x] Create recurring task
- [x] Complete recurring task
- [x] Verify next occurrence generated
- [x] Verify reminders fire correctly
- [x] Verify theme persistence
- [x] Verify signup flow

---

# Phase 7: APK Build

- **Build:** Priora v1.1.0
- **Version Code:** Incremented
- **Version Name:** `1.1.0`

### Artifacts:
- `app-arm64-v8a-release.apk`
- `app-release.apk`
- `app-release.aab`

---

# Phase 8: Beta Distribution

- Distribute v1.1.0 APK.
- Existing users may update voluntarily.
- Users who remain on v1.0.0 continue functioning.

---

# Rollback Strategy

### If backend issue detected:
- Rollback Render deployment.
- Database remains compatible.
- No user data loss.

### If frontend issue detected:
- Stop APK distribution.
- Keep backend running.
- Existing users unaffected.

---

# Success Criteria

Migration considered successful when:
- [x] Existing beta users continue working
- [x] No API regressions
- [x] No authentication failures
- [x] No notification failures
- [x] Theme synchronization works
- [x] Reminder audio works
- [x] Recurring tasks work
- [x] Recurring reminders work
- [x] No database errors

---

# Post-Migration State

- **Production Backend:** v1.1.0
- **Database:** v1.1.0 Schema
- **Supported Clients:**
  - ✓ Priora v1.0.0
  - ✓ Priora v1.1.0

---

*End of Document*
