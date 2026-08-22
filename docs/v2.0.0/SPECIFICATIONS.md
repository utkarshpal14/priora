# Priora v2.0.0 — Major Version Specifications & Architectural Backlog

> **Target Version:** v2.0.0 (Major Architecture Upgrade)  
> **Status:** Long-Term Roadmap  

---

## 1. Overview

Priora v2.0.0 introduces cloud synchronization infrastructure, multi-device push notifications, project breakdown hierarchies, and native desktop applications.

---

## 2. Planned Major Modules

### 1. Firebase Cloud Messaging (FCM) & Push Dispatcher
- **Multi-Device Notifications:** Cloud push notifications synced across mobile, web, and desktop.
- **Backend Scheduler Worker:** Asynchronous background worker queue (Celery / Redis / APScheduler) for cross-device push retry.

### 2. Project Planning System
- **Project Hierarchy:** Macro projects (e.g. Placement Prep, Course Roadmaps) broken into Monthly, Weekly, and Daily targets.
- **Manual Breakdown Rules:** User-controlled target planning without AI auto-mutation.

### 3. Calendar Integrations
- Two-way synchronization with Google Calendar, Outlook, and Apple Calendar.

### 4. Native Desktop Applications
- Native Flutter desktop distributions for macOS, Windows, and Linux.
