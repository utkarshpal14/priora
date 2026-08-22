# 🚀 Priora — Smart Productivity Platform

> **Plan. Prioritize. Progress.**

Priora is an intelligent, full-stack productivity platform built to help users seamlessly manage tasks, deadlines, reminders, long-term goals, hourly daily schedules, and supporting attachments in one unified workspace.

---

## 🌟 Key Features Showcase

### ⚡ Smart Task Management & Priority Matrix
- **Priority-Based Sorting:** Tasks sorted dynamically by priority (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`) and deadlines.
- **Overdue Detection & Urgency Banner:** Automatic calculation of overdue tasks with celebratory empty states when caught up.
- **Categories & Custom Color Styling:** Organize work into customizable categories.

### 🕒 Timezone-Aware Hourly Planner & Timeline
- **Auto-Placement Engine:** Incomplete and upcoming tasks scheduled for today are automatically positioned onto the hourly schedule timeline based on local timezone offsets (`tz_offset`).
- **Hourly Conflict Resolution:** Detects overlapping time blocks and presents visual conflict warnings.

### ⏰ Multi-Preset Reminder System
- **Preset Offsets:** Set reminders at deadline, 15 min before, 1 hour before, 1 day before, or pick a custom date/time.
- **Cross-Platform Notifications:** Local system notifications and Firebase Cloud Messaging support.

### 🌅 End-of-Day Evening Review
- **Reflection & Action Chips:** Evening review flow allowing users to complete, reschedule to tomorrow, or push tasks.
- **Celebration Recaps:** Detailed daily completion stats, streak tracking, and work duration recap dialogs.

### 🎯 Goals & Milestone Progression
- **Long-Term Objectives:** Track high-level goals linked to milestones and individual tasks.
- **Progress Tracking:** Automatic progress percentage calculation as milestones and linked tasks are completed.

### 📎 Multi-Entity Attachments & Resources (Milestone 8)
- **Universal Attachment Targets:** Attach resources to **Tasks**, **Goals**, or **Milestones** (`task_id` XOR `goal_id` XOR `milestone_id`).
- **4 Resource Types:**
  - 🖼️ **Images:** Automatic compression & thumbnail generation (`.webp` dual resolution).
  - 📄 **Documents:** Support for `.pdf`, `.doc`, `.docx`, `.txt`, `.md` (Play Store safe whitelist).
  - 🌐 **Web Links:** Automated site name, domain, and metadata extraction for external links (GitHub, Notion, Figma, etc.).
  - 📝 **Quick Notes:** In-app markdown revision notes with copy actions.
- **Tags & Pinning:** Tag organization (`#DSA`, `#OS`, `#Placement`) and resource pinning to top of lists.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Backend Framework** | [FastAPI](https://fastapi.tiangolo.com/) (Python 3.13) |
| **Database & ORM** | [PostgreSQL](https://www.postgresql.org/) / [Supabase](https://supabase.com/) with [SQLAlchemy 2.0](https://www.sqlalchemy.org/) |
| **Authentication** | OAuth2 Password Bearer with JWT (HS256) & Bcrypt password hashing |
| **Frontend Framework** | [Flutter](https://flutter.dev/) (Cross-Platform: Web, Desktop, Mobile) |
| **State Management** | [Flutter Riverpod](https://riverpod.dev/) (StateNotifier & Family Controllers) |
| **Routing** | [GoRouter](https://pub.dev/packages/go_router) with Auth Guard Protection |
| **Notifications** | Local Notifications (`flutter_local_notifications`) & FCM |

---

## 📊 Milestone Development Roadmap

- [x] **Milestone 0** — [Project Setup & Architecture](file:///docs/milestones/M0_Setup.md)
- [x] **Milestone 1** — [Authentication & User Isolation](file:///docs/milestones/M1_Authentication.md)
- [x] **Milestone 2** — [Task Management Core](file:///docs/milestones/M2_Task_Management.md)
- [x] **Milestone 3** — [Deadlines & Priority Matrix](file:///docs/milestones/M3_Deadlines_and_Priorities.md)
- [x] **Milestone 4** — [Reminder System & Notifications](file:///docs/milestones/M4_Reminder_System.md)
- [x] **Milestone 5** — [Hourly Planner & Auto-Placement Timeline](file:///docs/milestones/M5_Planner.md)
- [x] **Milestone 6** — [End-of-Day Review & Celebration Stats](file:///docs/milestones/M6_Review.md)
- [x] **Milestone 7** — [Goals & Milestone Progression](file:///docs/milestones/M7_Goals.md)
- [x] **Milestone 8** — [Attachments & Multi-Entity Resources](file:///docs/milestones/M8_Attachments.md)
- [x] **Milestone 9** — [Analytics & Productivity Reports](file:///docs/milestones/M9_Analytics.md)
- [x] **Milestone 10** — [UI Polish, Dark Mode Themes & Settings](file:///docs/milestones/M10_UI_Polish_and_Themes.md)
- [ ] **Milestone 11** — [End-to-End Integration Testing & Cloud Push Engine](file:///docs/milestones/M11_Integration_Testing_and_Notifications.md)
- [ ] **Milestone 12** — Production Release & Deployment

---

## 📑 Canonical System Documentation

- 📘 **Project Overview**: [`docs/PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md)
- 🏗️ **System Architecture**: [`docs/SYSTEM_ARCHITECTURE.md`](docs/SYSTEM_ARCHITECTURE.md)
- 🗄️ **Database Schema**: [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md)
- 🔌 **API Specification**: [`docs/API_SPECIFICATION.md`](docs/API_SPECIFICATION.md)
- 🎨 **UI/UX Specification**: [`docs/UI_UX_SPECIFICATION.md`](docs/UI_UX_SPECIFICATION.md)
- 🛠️ **Engineering Guidelines**: [`docs/ENGINEERING_GUIDELINES.md`](docs/ENGINEERING_GUIDELINES.md)
- 🗺️ **Product Roadmap**: [`docs/ROADMAP.md`](docs/ROADMAP.md)
- 🔮 **Future Vision & Backlog**: [`docs/FUTURE_VISION.md`](docs/FUTURE_VISION.md)
- 📜 **Changelog**: [`docs/CHANGELOG.md`](docs/CHANGELOG.md)

### Release Specifics
- 📦 **v1.0.0 Release Notes**: [`docs/v1.0.0/RELEASE_NOTES_V1.0.0.md`](docs/v1.0.0/RELEASE_NOTES_V1.0.0.md)
- 📋 **v1.0.0 Product Requirements**: [`docs/v1.0.0/PRODUCT_REQUIREMENTS.md`](docs/v1.0.0/PRODUCT_REQUIREMENTS.md)
- 🧪 **v1.0.0 Test Report & Matrix**: [`docs/v1.0.0/TEST_REPORT_V1.md`](docs/v1.0.0/TEST_REPORT_V1.md)
- 🏛️ **Historical Milestone Specs**: [`docs/archive/milestones/`](docs/archive/milestones/)

---

## 🚀 Getting Started Guide

### Prerequisites
- **Python:** 3.11+
- **Flutter SDK:** 3.24+
- **Database:** PostgreSQL (or SQLite for local dev)

### 1. Backend Setup

```bash
cd backend

# Create & activate virtual environment
python -m venv .venv
.venv\Scripts\activate  # On Windows

# Install dependencies
pip install -r requirements.txt

# Run database migrations / start dev server
uvicorn main:app --reload
```
The API server will run at `http://127.0.0.1:8000` (Interactive Swagger docs available at `http://127.0.0.1:8000/docs`).

### 2. Frontend Setup

```bash
cd frontend

# Install Flutter dependencies
flutter pub get

# Run on Chrome / Web
flutter run -d chrome
```

---

## 🧪 Verification & Testing

Priora maintains comprehensive test suites for both backend and frontend.

### Running Backend Pytest
```bash
cd backend
.venv\Scripts\pytest.exe
```
> **Result:** 52 / 52 Passed (100% Pass Rate)

### Running Frontend Flutter Tests
```bash
cd frontend
flutter test
```
> **Result:** 31 / 31 Passed (100% Pass Rate)