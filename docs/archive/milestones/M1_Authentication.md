# Milestone 1 — Authentication & User Management Specification

## 1. Overview
Milestone 1 implements secure authentication and user lifecycle management in Priora, providing user isolation across all tasks, goals, reminders, and resources.

---

## 2. Authentication Flow & Security

### Security Features
- **Password Hashing:** Passlib with `bcrypt` password hashing.
- **JWT Token Authentication:** OAuth2 Password Bearer flow with JSON Web Tokens (HS256).
- **Token Expiry:** 7-day access token expiration (`ACCESS_TOKEN_EXPIRE_MINUTES = 10080`).
- **User Data Isolation:** Every database table includes indexed `user_id` foreign key. All service queries filter strictly by `user_id == current_user.id`.

---

## 3. Database Schema

### `users` Table
| Column | Type | Description |
|---|---|---|
| `id` | `UUID` | Primary Key (Default: `uuid4`) |
| `email` | `VARCHAR(255)` | Unique, lowercase, indexed user email |
| `full_name` | `VARCHAR(255)` | Display name of user |
| `hashed_password` | `VARCHAR(255)` | Bcrypt hashed password |
| `is_active` | `BOOLEAN` | User account active state (default: `true`) |
| `storage_used_bytes` | `BIGINT` | Cumulative attachment file storage used |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | Creation timestamp (UTC) |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | Last updated timestamp (UTC) |

---

## 4. API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/v1/auth/register` | Register new user account |
| `POST` | `/api/v1/auth/login` | Authenticate user & issue JWT bearer token |
| `GET` | `/api/v1/auth/me` | Fetch current authenticated user profile |

---

## 5. Frontend Auth State Management
- `AuthController` manages authentication state (`AuthState.authenticated`, `AuthState.unauthenticated`).
- Automatic secure storage of JWT token.
- `GoRouter` redirect guards redirect unauthenticated users to `/login` and authenticated users to `/planner`.
