# Document 02 — Priora SRS v1.0

This is the most important document in the entire project.

### What the SRS Will Define

## Section 1 — Introduction

- Purpose
- Scope
- Definitions
- Assumptions
- Constraints
## Section 2 — User Roles

**For Priora V1:**

User

Only one role.

No admin panel.

No team accounts.

No collaboration.

## Section 3 — Functional Requirements

**Example:**

### FR-001 User Registration

**User shall be able to:**

- Create account
- Verify email
- Login
- Logout
### FR-002 Task Creation

**User shall be able to:**

- Create task
- Set title
- Set description
- Set priority
- Set deadline
- Set reminders
And so on for every feature.

## Section 4 — Non-Functional Requirements

**Example:**

### Performance

**Dashboard load:**

< 2 seconds

### Security

- JWT Authentication
- Secure Password Handling
- HTTPS Only
### Reliability

- Daily backups
- No task loss
### Usability

- Mobile-first
- Maximum 3 clicks to create task
### Scalability

**Support:**

10,000+

Tasks per user

## Section 5 — User Stories

**Example:**

### US-001

As a user,

I want to create a task,

So that I can track work I need to complete.

### US-002

As a user,

I want deadline reminders,

So that I don't miss important dates.

### US-003

As a user,

I want to reschedule unfinished tasks,

So that they remain organized.

## Section 6 — Use Cases

Detailed flow.

**Example:**

### Create Task

**Actor:**

User

**Precondition:**

Logged In

**Flow:**

Open Task Screen

```text
↓
Click Add
↓
Enter Details
↓
Save
Postcondition:
Task Created
```

## Section 7 — Feature Specifications

This is critical.

**Every feature gets:**

### Description

### Inputs

### Outputs

### Business Rules

### Edge Cases

**Example:**

### Reminder Feature

**Inputs:**

Deadline

Reminder Time

**Business Rules:**

Cannot set reminder after deadline.

**Edge Cases:**

User changes deadline.

## Section 8 — Constraints

**Examples:**

Free Hosting Only

Free Services Only

No Paid APIs

No AI Features

No Third-Party Premium Integrations

## Section 9 — Success Metrics

**Example:**

Task Completion Rate

Daily Active Users

Reminder Delivery Success Rate

Rescheduled Tasks

Weekly Retention

### After SRS Is Approved

**Only then move to:**

Document 03

Database Design

**where we'll define:**

- tables
- fields
- relationships
- indexes
- constraints
- ER diagram
### Recommendation

Go to the Priora project chat and create:

### "Document 02 — Priora SRS v1.0"

Don't start database design yet.
