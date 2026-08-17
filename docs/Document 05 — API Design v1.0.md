# Document 05 — API Design v1.0

This document defines **every endpoint** that Flutter can call and every response FastAPI will return.

Think of it as a contract between:

Flutter App

```text
↔
FastAPI Backend
```

### Why API Design Before Coding?

**Without API Design:**

Build UI

```text
↓
Need API
↓
Build API
↓
Need DB Changes
↓
Change UI
↓
Change API
↓
Mess
With API Design:
Design API
↓
Lock API
↓
Frontend + Backend become easy
```

### Structure of Document 05

## 1. API Overview

**Document:**

**Architecture:**

REST API

**Format:**

JSON

**Authentication:**

JWT

**Base URL:**

https://api.priora.app/api/v1

## 2. API Standards

**Example:**

### Success Response

```json
{
"success": true,
"message": "Task created successfully",
"data": {}
```

}

### Error Response

```json
{
"success": false,
"message": "Task not found",
"errors": []
}
```

Lock one standard format.

## 3. Authentication APIs

### Register

POST /auth/register

**Request:**

```json
{
"name": "Utkarsh",
"email": "abc@gmail.com",
"password": "password"
}
```

**Response:**

```json
{
"success": true
}
```

### Login

POST /auth/login

### Logout

POST /auth/logout

### Reset Password

POST /auth/reset-password

## 4. User APIs

### Get Profile

GET /users/me

### Update Profile

PUT /users/me

## 5. Task APIs

This will be the largest section.

### Create Task

POST /tasks

**Request:**

```json
{
"title": "Complete Assignment",
"description": "...",
"priority": "HIGH",
"deadline": "2026-08-30"
}
```

### Get Tasks

GET /tasks

**Filters:**

GET /tasks?status=pending

GET /tasks?priority=high

GET /tasks?category=college

### Get Task By ID

GET /tasks/{task_id}

### Update Task

PUT /tasks/{task_id}

### Delete Task

DELETE /tasks/{task_id}

### Complete Task

PATCH /tasks/{task_id}/complete

### Reopen Task

PATCH /tasks/{task_id}/reopen

## 6. Category APIs

### Create Category

POST /categories

### Get Categories

GET /categories

### Update Category

PUT /categories/{id}

### Delete Category

DELETE /categories/{id}

## 7. Reminder APIs

### Create Reminder

POST /reminders

### Get Reminders

GET /reminders

### Update Reminder

PUT /reminders/{id}

### Delete Reminder

DELETE /reminders/{id}

## 8. Goal APIs

### Create Goal

POST /goals

### Get Goals

GET /goals

### Goal Details

GET /goals/{goal_id}

### Update Goal

PUT /goals/{goal_id}

### Delete Goal

DELETE /goals/{goal_id}

### Add Goal Task

POST /goals/{goal_id}/tasks

## 9. Planner APIs

### Daily Planner

GET /planner/day

### Weekly Planner

GET /planner/week

### Monthly Planner

GET /planner/month

## 10. Review APIs

End-of-Day Review

### Get Review

GET /reviews/today

**Returns:**

```json
{
"pending_tasks": []
}
```

### Reschedule Task

POST /reviews/reschedule

### Keep Pending

POST /reviews/keep-pending

### Cancel Task

POST /reviews/cancel

## 11. Attachment APIs

### Upload File

POST /attachments/upload

### Get Attachments

GET /attachments

### Delete Attachment

DELETE /attachments/{id}

## 12. Analytics APIs

### Weekly Summary

GET /analytics/weekly

### Monthly Summary

GET /analytics/monthly

### Productivity Metrics

GET /analytics/productivity

## 13. Notification APIs

### Register Device Token

POST /notifications/device-token

### Get Notification Settings

GET /notifications/settings

### Update Notification Settings

PUT /notifications/settings

## 14. Error Codes

**Define:**

200 Success

201 Created

400 Bad Request

401 Unauthorized

403 Forbidden

404 Not Found

409 Conflict

422 Validation Error

500 Server Error

## 15. API Versioning Strategy

**Lock now:**

/api/v1/

**Future:**

/api/v2/

Never break existing APIs.
