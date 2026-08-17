# Document 04 — System Architecture v1.0

## 1. System Overview

Describe Priora at a high level.

**Example:**

Priora follows a client-server architecture.

**Frontend:**

Flutter Mobile Application

**Backend:**

FastAPI REST API

**Database:**

PostgreSQL (Supabase)

**Authentication:**

Supabase Auth

**Storage:**

Supabase Storage

**Notifications:**

Firebase Cloud Messaging

## 2. High-Level Architecture Diagram

**Create a diagram like:**

+------------------+

| Flutter App      |

+------------------+

|

|

v

+------------------+

| FastAPI Backend  |

+------------------+

|

|

+---------+---------+

|                   |

v                   v

PostgreSQL      Supabase Storage

|

|

v

Firebase Cloud Messaging

## 3. Architecture Principles

Lock these rules.

**Example:**

### AP-001

Frontend never talks directly to database.

Flutter

→ FastAPI

→ PostgreSQL

Only.

### AP-002

Business logic remains in backend.

Not inside Flutter.

### AP-003

Feature-first architecture.

Both frontend and backend.

### AP-004

**Every feature has:**

UI

State

API

Service

Database

## 4. Authentication Architecture

Explain login flow.

**Example:**

User Login

```text
↓
Supabase Auth
↓
JWT Token
↓
Flutter Stores Session
↓
Every API Request
↓
Token Validation
Questions to answer:
```

- Where is token stored?
- How is user identified?
- How is logout handled?
## 5. Task Management Architecture

**Flow:**

User Creates Task

```text
↓
Flutter Form
↓
Task API
↓
Task Service
↓
Database
↓
Response
↓
UI Updated
```

Create sequence diagrams.

## 6. Reminder Architecture

This is one of the most important sections.

**Flow:**

Task Created

```text
↓
Reminder Created
↓
Stored in Database
↓
Scheduler Checks
↓
Reminder Due
↓
FCM Push Notification
↓
User Receives Alert
Document:
```

- reminder creation
- reminder updates
- reminder deletion
## 7. Daily Planner Architecture

**Flow:**

User Opens Planner

```text
↓
Planner Service
↓
Fetch Tasks
↓
Apply Priority Rules
↓
Generate Daily Plan
↓
Return Schedule
Define:
```

- priority calculation
- deadline weighting
- overdue handling
## 8. End-of-Day Review Architecture

**Flow:**

10 PM Trigger

```text
↓
Check Pending Tasks
↓
Generate Review List
↓
User Opens Review
↓
Choose Action
Actions:
Reschedule
Keep Pending
Cancel
```

No automatic rescheduling.

## 9. Goal Management Architecture

**Flow:**

Create Goal

```text
↓
Create Milestones
↓
Create Tasks
↓
Track Progress
Goal Progress:
Completed Tasks
/
Total Tasks
```

## 10. Attachment Architecture

**Flow:**

Upload File

```text
↓
Supabase Storage
↓
Store URL
↓
Attach to Task
Supported:
Images
PDFs
Links
Notes
```

## 11. Notification Architecture

**Explain:**

### Local Notifications

Device reminders.

### Push Notifications

FCM reminders.

Document when each is used.

## 12. State Management Architecture

Since you're using Flutter + Riverpod.

**Document:**

UI

```text
↓
Provider
↓
Repository
↓
API Client
↓
Backend
Never:
UI
↓
API Directly
```

## 13. Backend Architecture

Document layers.

API Layer

```text
↓
Service Layer
↓
Repository Layer
↓
Database Layer
Responsibilities:
```

### API

Receives requests.

### Service

Business logic.

### Repository

Database operations.

## 14. Error Handling Strategy

**Example:**

401

Unauthorized

404

Not Found

500

Server Error

Define standard response format.

## 15. Security Architecture

**Document:**

- JWT validation
- Protected endpoints
- Input validation
- File upload validation
- Rate limiting (future)
## 16. Scalability Notes

Even though V1 is small.

**Document future growth:**

Calendar Sync

Teams

AI Features

Web Version

Without implementing them.
