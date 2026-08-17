# Document 01 — Priora Project Description

## Project Description

### What is Priora?

**Priora is a smart productivity and planning platform that helps users manage tasks, deadlines, reminders, recurring activities, and long-term goals from a single system.**

Unlike traditional to-do apps that only store tasks, Priora focuses on:

- Task organization
- Deadline tracking
- Intelligent scheduling
- Daily planning
- Long-term goal breakdown
- Reminder management
- End-of-day reviews
- Manual task rescheduling
- Attachment management
Priora acts as a personal planning assistant that ensures no important task is forgotten and unfinished work is properly handled.

### Problem Statement

Most students and professionals struggle with:

- Missing deadlines
- Forgetting assignments
- Ignoring reminders
- Poor planning
- Overloaded task lists
- Long-term goals without structure
- Unfinished tasks disappearing
Current apps like Google Tasks, Microsoft To Do, and many task managers mostly stop at task storage.

Priora focuses on the entire lifecycle of a task:

```text
Create
↓
Plan
↓
Schedule
↓
Remind
↓
Track
↓
Review
↓
Reschedule (if needed)
↓
Complete
```

### Core Objective

**Help users answer:**

### What do I need to do?

Task List

### What should I do today?

Daily Planner

### What happens if I don't finish it?

End-of-Day Review

### User Types

### Students

- Assignments
- Exams
- Courses
- Placement Preparation
- Projects
### Professionals

- Meetings
- Deadlines
- Projects
- Documentation
### General Users

- Personal Goals
- Fitness
- Habits
- Daily Tasks
### Core Entities

### Task

A unit of work.

**Example:**

Complete Assignment 3

**Contains:**

Title

Description

Priority

Deadline

Status

Category

Attachments

### Goal

Large objective.

**Example:**

Complete DNN Course

**Can be broken into:**

Monthly Tasks

Weekly Tasks

Daily Tasks

### Reminder

Notification linked to a task.

**Example:**

Assignment Due Tomorrow

### Schedule

Plan generated from tasks.

**Example:**

9-10 DSA

10-11 Assignment

### Workflow

### Step 1

User creates task.

**Task:**

Submit Internship Form

**Deadline:**

25 Aug

**Priority:**

High

Stored in database.

### Step 2

**Scheduling Engine checks:**

Priority

Deadline

Pending Tasks

Available Time

and places task into schedule.

### Step 3

Reminder Engine creates reminders.

**Example:**

7 days before

3 days before

1 day before

### Step 4

Daily Planner builds today's plan.

### Step 5

User completes task.

**Status:**

Completed

OR

Task remains pending.

### Step 6

End-of-Day Review.

Task completed?

Yes

No

**If No:**

Tomorrow

Custom Date

Cancel

Keep Pending

User decides.

### Major Modules

### Authentication

Signup/Login

### Task Management

CRUD Operations

### Categories

**Examples:**

College

Course

Personal

Work

Exam

### Scheduling Engine

Creates daily schedule.

### Reminder Engine

Creates reminders.

### Review Engine

Handles unfinished tasks.

### Goal Breakdown System

Goal

```text
↓
Monthly
↓
Weekly
↓
Daily
```

### Attachment System

**Store:**

Links

Images

PDFs

Notes

### System Architecture

Frontend (Flutter)

```text
↓
Supabase Auth
↓
FastAPI Backend
↓
PostgreSQL Database
↓
Notification Service
↓
Firebase Cloud Messaging
```

### Why Flutter?

Because FREE.

Single codebase.

Android

iOS

Web

Desktop

Later.

### Why FastAPI?

Free
Fast
Easy

You already know Python.

### Why PostgreSQL?

Industry Standard.

Free through Supabase.

### Why Supabase?

**Free Tier Includes:**

- Auth
- PostgreSQL
- Storage
No need for Firebase subscription.

### Final Tech Stack

### Frontend

Flutter

Riverpod

GoRouter

### Backend

FastAPI

SQLAlchemy

Pydantic

### Database

PostgreSQL

**Hosted on:**

Supabase

### Authentication

Supabase Auth

### Notifications

Firebase Cloud Messaging

Free

### Storage

Supabase Storage

### Recommended Folder Structure

### Frontend

lib/

```text
├── core/
│   ├── constants/
│   ├── theme/
│   ├── services/
│   └── utils/
│
├── features/
│
│   ├── auth/
│   ├── tasks/
│   ├── planner/
│   ├── reminders/
│   ├── review/
│   ├── goals/
│   └── attachments/
│
├── shared/
│
├── routes/
│
└── main.dart
```

### Backend

backend/

```text
├── app/
│
│   ├── api/
│   │
│   ├── models/
│   │
│   ├── schemas/
│   │
│   ├── services/
│   │
│   ├── repositories/
│   │
│   ├── scheduler/
│   │
│   ├── notifications/
│   │
│   └── core/
│
├── tests/
│
└── main.py
```

### Development Roadmap

## Phase 0

Planning

**Duration:**

3-5 Days

**Deliverables:**

- PRD
- Wireframes
- Database Design
- API Design
## Phase 1

Authentication

**Learn:**

Flutter Auth

Supabase Auth

**Build:**

Signup

Login

Logout

Forgot Password

## Phase 2

Task Management

**Build:**

Create Task

Update Task

Delete Task

View Task

## Phase 3

Categories

**Build:**

Task Categories

Filters

Search

## Phase 4

Reminder Engine

**Build:**

Push Notifications

Task Alerts

Deadline Alerts

## Phase 5

Daily Planner

**Build:**

Today's Plan

Schedule View

## Phase 6

End-of-Day Review

**Build:**

Review Screen

Reschedule Flow

## Phase 7

Recurring Tasks

**Build:**

Daily

Weekly

Monthly

## Phase 8

Attachments

**Build:**

Links

PDF

Images

## Phase 9

Goal System

**Build:**

Goal Creation

Goal Breakdown

Progress Tracking

## Phase 10

Analytics

**Build:**

Weekly Summary

Monthly Summary

Completion Rate

## Phase 11

Testing

Unit Testing

Integration Testing

UI Testing

## Phase 12

Deployment

Backend Deploy

Android Build

Play Store Publish

### Important Rule

**For Version 1:**

❌ No AI

❌ No GPT

❌ No Gemini

❌ No paid APIs

Build a rock-solid productivity system first.

A great task system with reminders, scheduling, reviews, and rescheduling is far more valuable than a half-finished "AI productivity app."

Once Priora v1 is stable and users actually use it, then think about intelligent planning features in a future version.
