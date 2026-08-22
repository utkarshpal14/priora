# Document 03 — Database Design v1.0

## 1. Database Overview

**Explain:**

**Database Type:**

PostgreSQL

**Provider:**

Supabase

**Architecture:**

Relational Database

## 2. Entity List

Every major entity.

**Example:**

User

Task

Goal

Reminder

Attachment

Category

RecurringTask

ReviewSession

## 3. ER Diagram

**Something like:**

User

|

+---- Tasks

|

+---- Goals

Task

|

+---- Reminders

|

+---- Attachments

Goal

|

+---- GoalTasks

It doesn't need to be graphical initially.

Text form is enough.

## 4. Table Definitions

**For every table:**

### Example

### tasks

id UUID PK

user_id UUID FK

title VARCHAR(255)

description TEXT

priority VARCHAR(20)

status VARCHAR(20)

deadline TIMESTAMP

created_at TIMESTAMP

updated_at TIMESTAMP

Then explain every field.

## 5. Relationships

**Example:**

### User → Tasks

One-to-Many

One user

Many tasks

### Task → Reminders

One-to-Many

### Goal → Tasks

One-to-Many

## 6. Constraints

**Examples:**

### Priority

**Allowed:**

LOW

MEDIUM

HIGH

CRITICAL

### Status

**Allowed:**

PENDING

IN_PROGRESS

COMPLETED

CANCELLED

### Deadline

**Rule:**

Cannot be before creation date.

## 7. Indexes

**Example:**

### tasks.deadline

**Reason:**

Fast upcoming-deadline queries.

### tasks.user_id

**Reason:**

Fast task retrieval.

## 8. Soft Delete Strategy

Decide now.

**Either:**

### Hard Delete

Delete forever.

or

### Soft Delete

is_deleted BOOLEAN

**Personally I'd choose:**

Soft Delete

for Priora.

## 9. Future Expansion Notes

**Document:**

Future Team Collaboration

Future Calendar Sync

Future AI Features

Even if V1 won't implement them.

This prevents painful migrations later.
