# Priora v1.1.0 API Compatibility Specification

Version: 1.1.0  
Status: Frozen / Approved (v1.1.0 Baseline)  
Freeze Date: August 25, 2026  
Compatibility Target: 100% Backward Compatible  

---

# Purpose

This document defines the API evolution strategy for Priora.

The goal is to allow new features to be added without breaking any existing v1.0.0 clients.

---

# Compatibility Policy

Existing Priora v1.0.0 APK users must continue functioning after all v1.1.0 deployments.

No update should be required for existing users.

---

# Golden Rule

Existing API contracts are immutable.

- Existing request formats must remain valid.
- Existing response formats must remain valid.

---

# Allowed Changes

The following are permitted:

- ✓ Add optional response fields
- ✓ Add optional request fields
- ✓ Add new API endpoints
- ✓ Add new query parameters
- ✓ Add new backend services
- ✓ Add new database-backed functionality

---

# Forbidden Changes

The following are prohibited:

- ✗ Remove response fields
- ✗ Rename response fields
- ✗ Change response data types
- ✗ Remove request fields currently in use
- ✗ Rename endpoints
- ✗ Change endpoint URLs
- ✗ Change authentication flow
- ✗ Break existing clients

---

# Authentication APIs

### Endpoints:
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `GET /api/v1/auth/me`

### Compatibility Requirements
These endpoints must remain unchanged. Existing APK users depend on them.

### Required Response Fields

**Registration:**
- `success`
- `message`
- `data`

**Login:**
- `access_token`
- `refresh_token`
- `user`

**User Profile:**
- `id`
- `email`
- `name`

---

# Task APIs

### Current Endpoints
- `GET /tasks`
- `POST /tasks`
- `PUT /tasks/{id}`
- `DELETE /tasks/{id}`

### Existing Response Example
```json
{
  "id": "uuid",
  "title": "DSA Practice",
  "priority": "high"
}
```

### v1.1 Extension (Allowed)
```json
{
  "id": "uuid",
  "title": "DSA Practice",
  "priority": "high",
  "repeat_type": "daily",
  "repeat_interval": 1
}
```

New fields are optional. Existing APK ignores them safely.

---

# Goal APIs

Existing goal endpoints must remain unchanged.

New goal functionality may only be added through optional fields or new endpoints.

---

# Reminder APIs

Existing reminder scheduling must remain operational.

Current reminder payloads must remain valid.

### v1.1 Reminder Extensions (Allowed)
```json
{
  "id": "uuid",
  "reminder_time": "2026-08-25T19:00:00Z",
  "repeat_type": "daily"
}
```

Existing clients ignore new fields.

---

# Recurring Task APIs

### New Feature
Recurring tasks may introduce:
- `repeat_type`
- `repeat_interval`
- `repeat_end_date`

These fields must always be optional.

### Example Create Task Request
```json
{
  "title": "DSA Practice"
}
```
*Must still work.*

### Enhanced Request
```json
{
  "title": "DSA Practice",
  "repeat_type": "daily",
  "repeat_interval": 1
}
```
*Must also work.*

---

# Error Response Compatibility

### Current Error Format
```json
{
  "success": false,
  "message": "Error message",
  "errors": []
}
```
*Must remain unchanged.*

---

# Health Endpoint

### Endpoint:
`GET /api/v1/health`

- Must remain publicly accessible.
- Must continue returning:
  - `status`
  - `environment`
  - `api_version`
  - `timestamp`

---

# Versioning Policy

### Current Version:
`v1`

- Remain unchanged.
- Do not create `/api/v2` during v1.1.0 development.
- All improvements must remain within `/api/v1`.

---

# Mixed Version Support

### Environment A
**v1.0.0 APK + v1.1.0 Backend**  
*Expected:* Fully Functional

---

### Environment B
**v1.1.0 APK + v1.1.0 Backend**  
*Expected:* Fully Functional

---

### Environment C
**Multiple APK Versions**  
*Expected:* All Supported

---

# Deployment Verification

Before backend deployment verify:
- [x] Login works
- [x] Registration works
- [x] Task creation works
- [x] Reminder creation works
- [x] Goal creation works
- [x] Existing APK functions
- [x] Health endpoint responds
- [x] No response contract changes

---

# Release Gate

Backend deployment may proceed only if:
- Existing APK remains functional
- Existing APIs remain compatible
- Existing database records remain valid
- No breaking contract changes exist

---

*End of Document*
