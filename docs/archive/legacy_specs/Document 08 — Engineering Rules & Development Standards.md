# Document 08 — Engineering Rules & Development Standards

## 1. Purpose

This document defines the engineering standards, development principles, architectural constraints, coding conventions, and AI-agent rules for Priora.

All development must follow these standards unless explicitly updated in a newer version of this document.

## 2. Core Project Principles

### ER-001 Scope Discipline

No feature may be implemented unless it exists in:

- Vision & Scope Document
- SRS Document
Avoid feature creep.

### ER-002 Free Ecosystem Only

Priora must be buildable and deployable using free-tier services.

### Allowed

- Flutter
- FastAPI
- PostgreSQL
- Supabase Free Tier
- Firebase Cloud Messaging
- GitHub
- Vercel (if needed)
- Render (if needed)
### Not Allowed

- Paid APIs
- Paid AI Services
- Premium SaaS dependencies
### ER-003 Cross-Platform Ready

Priora is designed as a cross-platform product.

### Initial Release

Android

### Future Support

Flutter Web

### Rule

All architecture decisions must remain compatible with Flutter Web.

Avoid Android-only implementations unless absolutely necessary.

### ER-004 User Control First

Priora is not an AI decision-making system.

**Users must always control:**

- Deadlines
- Rescheduling
- Task priorities
- Goal management
The system may assist but never decide on behalf of users.

### ER-005 Simplicity Over Complexity

**Prefer:**

Simple

Maintainable

Readable

**Avoid:**

Over-engineering

Premature optimization

Complex abstractions

## 3. Frontend Engineering Standards

### FE-001 Framework

Flutter

Only.

### FE-002 State Management

Riverpod

Only.

**Do not mix:**

- Provider
- GetX
- Bloc
### FE-003 Routing

GoRouter

Only.

### FE-004 Architecture Pattern

Feature-first architecture.

**Example:**

lib/

core/

shared/

routes/

features/

auth/

tasks/

planner/

goals/

reminders/

attachments/

analytics/

### FE-005 Layer Flow

**Always:**

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

### FE-006 Design System Compliance

**Every screen must follow:**

Document 07

Design System & Product Identity

No exceptions.

## 4. Product Design Rules

This section is critical.

Priora must not look like a generic student project.

### UI Philosophy

**Inspired by:**

- Linear
- Notion
- Arc Browser
- Things 3
- TickTick
- Sunsama
### Avoid

- Default Flutter Material layouts
- Generic dashboard templates
- Blue-white productivity clones
- Admin-panel style screens
### Prioritize

- Typography
- Spacing
- Hierarchy
- Usability
- Accessibility
**Over:**

- Fancy effects
- Colorful cards
- Excessive animations
### Motion Rules

**Animation duration:**

200–300ms

**Allowed:**

Fade

Slide

Scale

**Avoid:**

Bounce

Flashy transitions

## 5. Backend Engineering Standards

### BE-001 Framework

FastAPI

Only.

### BE-002 Layered Architecture

Router

```text
↓
Service
↓
Repository
↓
Database
```

### BE-003 Business Logic Location

Business logic belongs only in:

Service Layer

### BE-004 Database Access

Database operations belong only in:

Repository Layer

### BE-005 API Consistency

**All APIs must follow:**

/api/v1/

Versioning strategy.

## 6. Database Rules

### DB-001 IDs

**Use:**

UUID

Never auto-increment integers.

### DB-002 Audit Fields

**Every table must include:**

created_at

updated_at

### DB-003 Soft Deletes

**Prefer:**

deleted_at

or

is_deleted

instead of permanent deletion.

### DB-004 Constraints

**All constraints defined in:**

Database Design Document

must be enforced.

## 7. API Standards

### API-001 Response Format

**Success:**

```json
{
"success": true,
"message": "Success",
"data": {}
```

}

**Error:**

```json
{
"success": false,
"message": "Error",
"errors": []
}
```

### API-002 Status Codes

**Supported:**

200 OK

201 Created

400 Bad Request

401 Unauthorized

403 Forbidden

404 Not Found

409 Conflict

422 Validation Error

500 Internal Server Error

## 8. Security Standards

### SEC-001 Secrets

**Never store:**

API Keys

JWT Secrets

Passwords

inside source code.

**Use:**

.env

files.

### SEC-002 Input Validation

**Validate:**

- Requests
- Forms
- File uploads
- API payloads
### SEC-003 Authentication

**Use:**

JWT

for protected endpoints.

## 9. Git Standards

### Branch Strategy

main

develop

feature/*

bugfix/*

### Commit Style

**feat:**

**fix:**

**refactor:**

**docs:**

**test:**

**style:**

**Examples:**

feat: add task creation api

fix: resolve reminder scheduling bug

docs: update srs

## 10. Code Quality Rules

### CQ-001 File Size

**Prefer:**

< 500 lines

per file.

### CQ-002 Naming

Use meaningful names.

**Bad:**

temp

data

obj

**Good:**

taskRepository

plannerService

goalProgressProvider

### CQ-003 Reusability

Avoid duplicated logic.

Extract reusable components.

## 11. Testing Standards

### Required Before Feature Completion

**Backend:**

- Unit Tests
- API Tests
**Frontend:**

- Widget Tests (critical screens)
### Definition

A feature is not complete until tests pass.

## 12. AI Agent Rules

All coding agents must follow:

- Vision & Scope
- SRS
- Database Design
- API Design
- UI/UX Design
- Design System
- Engineering Rules
### Agents May Not

- Change architecture
- Add features
- Modify database design
- Ignore design system
Without explicit approval.

### Agents May

- Implement approved features
- Refactor code
- Improve performance
- Fix bugs
While preserving architecture.

## 13. Definition of Done (DoD)

A feature is considered complete only when:

UI Completed

Backend Completed

Database Completed

API Integrated

Tests Passing

No Critical Bugs

Documentation Updated

Design System Followed

## 14. Long-Term Vision Protection

**Future versions may add:**

Flutter Web

Calendar Integrations

Collaboration Features

AI Assistance

Desktop Applications

Current development must avoid decisions that would block these future expansions.
