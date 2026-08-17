# Document 09 — Implementation Roadmap & Milestones

This is where Priora transforms from:

Idea

→ Documentation

→ Development Plan

into

Daily Development Tasks

### Purpose

**Answer:**

What exactly should I build first?

What comes second?

What depends on what?

How do I avoid getting lost?

### Milestone Strategy

I recommend **Vertical Slice Development**.

**Avoid:**

```text
Build entire frontend
↓
Build entire backend
↓
Integrate
Instead:
Feature
↓
Frontend
↓
Backend
↓
Database
↓
Testing
↓
Next Feature
```

Much safer.

## Milestone 0 — Project Setup

### Goal

Create project foundation.

### Frontend

- Flutter Project
- Riverpod Setup
- GoRouter Setup
- Theme Setup
- Folder Structure
- Environment Config
### Backend

- FastAPI Setup
- PostgreSQL Connection
- Supabase Setup
- Environment Variables
- Basic Health Endpoint
### Deliverable

Project Runs Successfully

## Milestone 1 — Authentication

### Features

### Signup

### Login

### Logout

### Forgot Password

### Session Management

### Database

users

### APIs

POST /auth/register

POST /auth/login

POST /auth/logout

### Deliverable

User can create account and login.

## Milestone 2 — Task Management (Core)

This is the heart of Priora.

### Features

### Create Task

### Edit Task

### Delete Task

### Complete Task

### Reopen Task

### Search Tasks

### Filter Tasks

### Database

tasks

categories

### APIs

/tasks

/categories

### Deliverable

Full Task CRUD Working

## Milestone 3 — Deadlines & Priorities

### Features

### Deadlines

### Priority Levels

Low

Medium

High

Critical

### Overdue Detection

### Upcoming Deadlines

### Deliverable

Task Management Feels Useful

## Milestone 4 — Reminder System

Very important.

### Features

### Create Reminder

### Update Reminder

### Delete Reminder

### Reminder Notifications

### Integrations

Firebase Cloud Messaging

### Deliverable

User Receives Notifications

## Milestone 5 — Planner

One of Priora's main differentiators.

### Features

### Daily Planner

### Weekly Planner

### Monthly Planner

### Timeline View

### Upcoming View

### Deliverable

Tasks organized into schedules

## Milestone 6 — End-of-Day Review

Signature feature.

### Features

### Pending Tasks Review

### Reschedule Task

### Keep Pending

### Cancel Task

### Deliverable

No task is forgotten

## Milestone 7 — Goals

### Features

### Create Goal

### Edit Goal

### Goal Progress

### Goal Tasks

### Deliverable

Long-Term Planning Works

## Milestone 8 — Attachments

### Features

### Upload Images

### Upload PDFs

### Attach Links

### Notes

### Supabase Storage

Integration.

### Deliverable

Tasks can contain supporting resources

## Milestone 9 — Analytics

### Features

### Completion Rate

### Weekly Summary

### Monthly Summary

### Productivity Stats

### Deliverable

User can see progress

## Milestone 10 — Polish

### UI Improvements

### Animations

### Loading States

### Empty States

### Error States

### Dark Mode (Optional)

### Deliverable

Production-Level Feel

## Milestone 11 — Testing

### Backend

- Unit Tests
- API Tests
### Frontend

- Widget Tests
### Deliverable

Stable Release Candidate

## Milestone 12 — Deployment

### Backend

- Render
or

- Railway (if free tier available then)
### Database

Supabase

### Mobile

Google Play Store

### Deliverable

Priora v1.0 Released

### Development Order (Important)

**Build in this exact order:**

0 Setup

1 Auth

2 Tasks

3 Deadlines

4 Reminders

5 Planner

6 Review

7 Goals

8 Attachments

9 Analytics

10 Polish

11 Testing

12 Release

Do **not** jump to Goals, Analytics, or fancy UI before Tasks + Reminders are fully working.
