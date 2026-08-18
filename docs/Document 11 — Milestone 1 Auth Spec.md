# Document 11 — Milestone 1: Authentication Specification v1.0

## 1. Authentication Strategy & Scope

### Supported Authentication Methods (Locked for V1)
- **Email + Password** (Primary)
- **Google Sign-In** (OAuth 2.0 / ID Token exchange)

### Explicitly Excluded in V1
- ❌ GitHub, Facebook, Twitter/X, Apple Login
- ❌ SMS / OTP Phone Login
- ❌ Biometric Login (FaceID / Fingerprint)

---

## 2. Session & Security Model

- **Access Token:** JWT Bearer token (short-lived, 60 minutes) carrying `sub` (User UUID) and `email`.
- **Refresh Token:** Long-lived token used to generate new access tokens without forcing re-login.
- **Client Storage:** Securely persisted in device storage; injected via Dio request interceptor (`Authorization: Bearer <token>`).
- **Route Guard:** GoRouter automatically redirects unauthenticated users to `/login` and authenticated users to `/dashboard`.

---

## 3. Database Schema (`users` table)

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NULL, -- Null for Google OAuth users
    full_name VARCHAR(255) NULL,
    avatar_url VARCHAR(512) NULL,
    auth_provider VARCHAR(20) NOT NULL DEFAULT 'email', -- 'email' | 'google'
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

---

## 4. API Endpoints Contract (`/api/v1/auth` & `/api/v1/users`)

| Method | Endpoint | Description | Request Body | Response Data |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/register` | Register new email account | `{ email, password, full_name? }` | `{ user, tokens }` |
| `POST` | `/api/v1/auth/login` | Email/password login | `{ email, password }` | `{ user, tokens }` |
| `POST` | `/api/v1/auth/google` | Google OAuth token verification | `{ id_token }` | `{ user, tokens }` |
| `POST` | `/api/v1/auth/refresh` | Refresh expired access token | `{ refresh_token }` | `{ tokens }` |
| `POST` | `/api/v1/auth/logout` | Invalidate current session | `{}` | `null` |
| `GET` | `/api/v1/users/me` | Fetch authenticated user profile | *(Bearer token header)* | `{ user }` |

---

## 5. Frontend Architecture (`lib/features/auth/`)

```text
features/auth/
├── data/
│   ├── auth_api.dart
│   └── auth_repository.dart
├── domain/
│   ├── user_model.dart
│   └── auth_tokens.dart
├── presentation/
│   ├── controllers/
│   │   └── auth_controller.dart (StateNotifier / AsyncNotifier)
│   ├── screens/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── widgets/
│       ├── auth_text_field.dart
│       └── google_sign_in_button.dart
```

---

## 6. UI & Design Rules

- **Background:** `#F8F6F2` (Warm Ivory)
- **Primary Elements:** `#1D1D1D` (Deep Charcoal)
- **Accent:** `#2D6A4F` (Muted Emerald)
- **Layout Order on Login Screen:**
  1. Brand Header (Priora logo, "Welcome back", "Sign in to continue")
  2. "Continue with Google" Button (Outlined, rounded-12)
  3. Visual Divider ("or continue with email")
  4. Email & Password Input Fields
  5. Primary CTA ("Sign In", Charcoal fill)
  6. Switch Screen Footer ("Don't have an account? Sign up")
