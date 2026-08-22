# Milestone 0 — Setup & Foundation Specification

## 1. Overview
Milestone 0 establishes the foundational setup, project structure, coding standards, and initial architecture for both the Priora backend (FastAPI, SQLAlchemy, PostgreSQL) and frontend (Flutter, Riverpod, GoRouter).

---

## 2. Architecture & Design Principles

### Backend Architecture (FastAPI & SQLAlchemy)
- **Layered Architecture:**
  - `app/api/v1/`: API endpoints with dependency injection for auth & database sessions.
  - `app/services/`: Business logic layer.
  - `app/repositories/`: Data access layer executing SQLAlchemy queries.
  - `app/models/`: SQLAlchemy ORM database models inheriting from `BaseDBModel`.
  - `app/schemas/`: Pydantic v2 schemas for request validation & response serialization.
- **Database & Persistence:** PostgreSQL / Supabase with SQLAlchemy 2.0 ORM.
- **Base Model Standard (`BaseDBModel`):**
  - Includes `id` (UUID PK), `created_at` (UTC timestamp), `updated_at` (UTC timestamp).

### Frontend Architecture (Flutter & Riverpod)
- **Feature-First Folder Structure:**
  - `lib/features/<feature_name>/` containing `data/`, `domain/`, `presentation/`.
- **State Management:** Riverpod (`StateNotifierProvider`, `Provider`, family providers).
- **Navigation:** `GoRouter` with auth-guard routing.
- **Design System:** Standardized tokens (`AppColors`, Google Fonts `Inter`, custom card designs, glassmorphism, responsive bottom sheets).

---

## 3. Environment & Configuration

### Backend Environment Variables (`.env`)
```env
PROJECT_NAME="Priora"
API_V1_STR="/api/v1"
DATABASE_URL="postgresql://user:pass@localhost:5432/priora"
SECRET_KEY="your-super-secret-jwt-key"
ALGORITHM="HS256"
ACCESS_TOKEN_EXPIRE_MINUTES=10080
```

### Frontend Configuration
- Multi-platform support: Android, iOS, Windows, macOS, Linux, and Web (Chrome).
- Dio HTTP client configured with base URL, headers, and token interceptors.

---

## 4. Verification & Testing Standards
- Automated backend testing using `pytest`.
- Automated frontend testing using `flutter test`.
