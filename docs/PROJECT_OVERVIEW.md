# Priora — Project Overview & Product Vision

> **Version:** v1.0.0 (Build 100 / RC1 Approved)  
> **Platform:** Cross-Platform Mobile (Android Primary, iOS Support) & Web/Desktop Backend  
> **Status:** Production Release Ready  
> **Repository:** `utkarshpal14/priora`  

---

## 1. Executive Summary

**Priora** is a high-performance productivity workspace designed to help users plan, prioritize, and execute their daily goals with certainty. Unlike traditional to-do list applications, Priora combines **task management, hourly time-blocking planner, goal tracking, evening review routines, analytics, and instant/scheduled notifications** into a unified ecosystem.

Priora v1.0.0 addresses core productivity failure modes (procrastination, missed deadlines, fragmented scheduling) by introducing an **Hourly Timeline Planner as the primary landing home screen**, supported by a robust native Android notification engine.

---

## 2. Core Value Proposition & Principles

1. **Planner-First Experience:** The application opens directly on **Today's Plan** (`/planner`), placing the daily schedule and hourly focus blocks at the user's fingertips.
2. **Guaranteed Local Notification Delivery:** Scheduled reminders, deadline alerts, and overdue notifications trigger reliably on physical hardware via `flutter_local_notifications` and exact alarm scheduling (`priora_reminders_v5`).
3. **Transparent System Diagnostics (`UX-003`):** Built-in settings diagnostics directly inspect Android `PowerManager.isIgnoringBatteryOptimizations` and `canScheduleExactAlarms` to guarantee notification reliability.
4. **Privacy & Offline First:** Local database caching combined with PostgreSQL synchronization ensures instant UI responsiveness regardless of network latency.

---

## 3. High-Level Feature Architecture

```
Priora Mobile Application (Flutter Client)
│
├── 📅 Today's Plan (Planner Screen)
│   ├── Calendar Strip
│   ├── Overdue Task Alerts
│   ├── Hourly Time Blocking & Session Editing
│   ├── Top 3 Smart Focus Priorities
│   └── Evening Review Banner
│
├── 📝 Task Management
│   ├── Task Lists (All, Today, Upcoming, Overdue, Completed)
│   ├── Smart Urgency Banner
│   ├── Category Filtering & Search
│   └── Create / Edit Bottom Sheet Modals
│
├── 🎯 Goal Tracking
│   ├── Target Date & Progress Percentages
│   ├── Sub-Goals Breakdown
│   └── Linked Task Association
│
├── 📊 Analytics & Progress
│   ├── Task Completion Velocity
│   ├── Category Workload Breakdown
│   └── Weekly Productivity Metrics
│
├── ⚙️ System Settings & Diagnostics (UX-003)
│   ├── Theme Modes & Color Palettes
│   ├── Live Battery Optimization Diagnostic
│   ├── Exact Alarm Capability Check
│   └── Test Notification Trigger (5s Alert)
│
└── 🔔 Notification Engine (v5)
    ├── Immediate Test Notifications
    ├── Scheduled Task Reminders
    ├── Overdue Task Delivery
    └── Heads-Up Banners & 4.5s Custom Vibration Pattern
```

---

## 4. Technology Stack & Architectural Footprint

| Component | Technology | Version | Purpose |
|---|---|---|---|
| **Mobile Frontend** | Flutter / Dart | 3.x / Dart 3.x | Cross-platform UI framework |
| **State Management** | Flutter Riverpod | 2.x | Reactive state, dependency injection, and state providers |
| **Navigation & Routing** | GoRouter | 14.x | Declarative shell routing with persistent bottom navigation scaffold |
| **Local Notifications** | `flutter_local_notifications` | 17.x | Android exact alarm scheduling, notification channels, and background receivers |
| **Timezone Support** | `timezone` package | Latest | Wall-clock time scheduling across system timezones |
| **Backend API** | FastAPI / Python | 0.100+ / 3.11+ | Asynchronous RESTful API framework |
| **Database ORM** | SQLAlchemy / Asyncpg | 2.0+ | Asynchronous database access and migration mapping |
| **Database Engine** | PostgreSQL | 15+ | Relational persistence store |
| **Authentication** | OAuth2 / JWT & Google Auth | PyJWT / Google APIs | Secure bearer token and OAuth2 authentication |

---

## 5. Repository Directory Layout

```
priora/
├── backend/                  # FastAPI Python Service
│   ├── app/
│   │   ├── api/              # REST Endpoints (v1)
│   │   ├── core/             # Security, Auth, DB Config
│   │   ├── models/           # SQLAlchemy Models
│   │   ├── schemas/          # Pydantic Request/Response Schemas
│   │   └── services/         # Business Logic Layer
│   ├── tests/                # Pytest Suite
│   └── main.py               # Application Entry Point
│
├── frontend/                 # Flutter Mobile Client
│   ├── android/              # Native Android App & Manifest Config
│   │   └── app/
│   │       ├── proguard-rules.pro  # R8 Shrinker Keep Rules
│   │       └── src/main/res/raw/   # Custom Audio Assets (priora_alert.wav)
│   ├── lib/
│   │   ├── core/             # Theme, Services, Notification Engine
│   │   ├── features/         # Feature Modules (Auth, Tasks, Planner, Goals, Settings, Analytics)
│   │   ├── routes/           # GoRouter Configuration (`app_router.dart`)
│   │   ├── shared/           # MainScaffold & Shared Widgets
│   │   └── main.dart         # Flutter Entry Point
│   └── test/                 # 44 Widget & Unit Integration Tests
│
└── docs/                     # Documentation Set
    ├── active/               # Canonical v1.0.0 Documentation Set
    └── archive/              # Historical Spec & Milestone Archive
```
