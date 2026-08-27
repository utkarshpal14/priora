# Priora v1.1.0 Technical Specifications

Version: 1.1.0  
Status: Frozen / Approved (v1.1.0 Baseline)  
Freeze Date: August 25, 2026  
Compatibility Target: 100% Backward Compatible with v1.0.0  

---

# Architecture Principles

All v1.1.0 changes must preserve functionality for existing v1.0.0 APK users.

### Allowed:
- Add new database columns
- Add new API fields
- Add new endpoints
- Add new frontend screens

### Forbidden:
- Remove columns
- Rename columns
- Change response contracts
- Break existing endpoints

---

# TS-001 Global Theme Synchronization

## Current Problem
Theme changes only affect Settings screen.

## Target Architecture
Theme state must become a global application state.

**Current:**
Settings Screen Theme State

**Target:**
```
App Theme Provider
├── Dashboard
├── Planner
├── Tasks
├── Goals
├── Settings
└── Navigation Shell
```

## Riverpod Requirements
Create:
- `ThemeNotifier`
- `ThemeRepository`
- `ThemePreferencesService`

Persist:
- Light
- Dark
- System

using `SharedPreferences`.

## Acceptance Criteria
- Theme updates entire app immediately.
- Theme survives restart.
- Theme survives logout/login.

---

# TS-002 Enhanced Reminder Audio

## Objective
Play a custom notification sound when reminders fire.

## Notification Behaviour

```
Reminder Triggered
        ↓
Notification Displayed
        ↓
Custom Priora Sound Plays
        ↓
Auto Stop after 3–5 Seconds
```

## Requirements

### Sound:
- `.mp3` or `.wav`
- bundled with application

### Duration:
- 3–5 seconds

### Must Not:
- Loop infinitely
- Behave as alarm clock
- Require dismissal

## Android Implementation

**Notification Channel:**  
Priora Reminders

**Custom Sound:**  
`res/raw/priora_reminder.mp3`

## Acceptance Criteria
- Reminder remains visible.
- Audio automatically stops.

---

# TS-003 Recurring Tasks

## Objective
Support repeating tasks.

## Supported Frequencies
- None
- Daily
- Weekly
- Monthly

**Future:**
- Custom

---

# Database Changes

**Table:**  
`tasks`

**Add Columns:**
- `repeat_type`
- `repeat_interval`
- `repeat_end_date`

**Schema:**
```sql
ALTER TABLE tasks ADD COLUMN repeat_type VARCHAR(20) DEFAULT 'none';
ALTER TABLE tasks ADD COLUMN repeat_interval INTEGER DEFAULT 1;
ALTER TABLE tasks ADD COLUMN repeat_end_date TIMESTAMP NULL;
```

## Compatibility
- All new columns must be nullable or have safe defaults.
- Existing rows must remain valid.

---

# Task Lifecycle

### Example:

**Task:**  
DSA Practice  

**Repeat:**  
Daily  

**Reminder:**  
7 PM  

---

#### Day 1
```
Task Created
     ↓
Reminder Sent
     ↓
Task Completed
     ↓
Next Occurrence Generated
```

---

#### Day 2
```
Task Visible Again
     ↓
Reminder Sent
     ↓
Completion
     ↓
Next Occurrence Generated
```

---

# Recurring Task Engine

When task marked completed:

`IF repeat_type != none`  
Generate next occurrence.

### Rules:
- **Daily:** `+1 Day`
- **Weekly:** `+7 Days`
- **Monthly:** `+1 Month`

---

# API Changes

All additions must be optional.

**Current Response:**
```json
{
  "title": "DSA Practice"
}
```

**Future Response:**
```json
{
  "title": "DSA Practice",
  "repeat_type": "daily",
  "repeat_interval": 1
}
```

Existing clients ignore new fields.

---

# TS-004 Recurring Reminders

Reminder schedule must follow task schedule.

### Examples:
- **Daily:** 7 PM
- **Weekly:** Monday 8 PM
- **Monthly:** 1st Day 9 AM

When next task occurrence generated:  
*Generate next reminder automatically.*

---

# TS-005 Data Migration Strategy

**Migration Type:** Non-Destructive

### Allowed:
- `ALTER TABLE ADD COLUMN`

### Forbidden:
- `DROP COLUMN`
- `ALTER COLUMN TYPE`
- `RENAME COLUMN`

---

# TS-006 Compatibility Verification

### Environment A
**v1.0.0 APK + v1.1.0 Backend**  
*Expected:* Fully Functional

---

### Environment B
**v1.1.0 APK + v1.1.0 Backend**  
*Expected:* All New Features Functional

---

### Environment C
**Mixed Users**  
*Expected:* No Regression

---

# Release Gate

v1.1.0 cannot release unless:

- [x] Existing APK functions
- [x] Login works
- [x] Registration works
- [x] Notifications work
- [x] Theme works globally
- [x] Recurring tasks work
- [x] Reminder audio works

---

# TS-007 Release Build Stability Fix

### Issue
Notifications and custom reminder sounds worked in debug mode (`flutter run`) but failed in release APKs (`flutter build apk --release`).

### Root Cause
Android release optimization removed required resources (`.wav` audio assets in `res/raw`) and stripped notification-related classes.

### Resolution
Disabled minification and resource shrinking in `android/app/build.gradle.kts`:
- `isMinifyEnabled = false`
- `isShrinkResources = false`

### Result
- Reminder delivery restored
- Sound previews restored
- Custom notification sounds restored
- Release APK verified on Android 13 device

---

# TS-008 Developer-Controlled In-App Update Architecture

## Objective
Provide an Over-The-Air (OTA) version verification and update delivery pipeline with strict isolation between private test builds and public release broadcasts.

## Architecture

```text
┌─────────────────────────────────────────────────────────┐
│              Backend Public Version API                 │
│             GET /api/v1/system/app-version              │
│                                                         │
│  Response:                                              │
│  {                                                      │
│    "latest_public_version": "1.1.0",                    │
│    "min_supported_version": "1.0.0",                    │
│    "apk_download_url": "https://.../priora.apk",        │
│    "release_notes": "Custom audio, themes, recurrence", │
│    "is_force_update": false                             │
│  }                                                      │
└────────────────────────────┬────────────────────────────┘
                             │
                  App Launch Version Check
                             │
               ┌─────────────┴─────────────┐
               ▼                           ▼
    [Private Dev Build]           [Public Outdated Client]
    Installed (1.1.0-dev)         Installed (1.0.0)
    >= Public (1.1.0)             < Public (1.1.0)
    👉 No popup                   👉 Triggers Update Dialog
```

## Implementation Components

### 1. Backend Endpoint (`/api/v1/system/app-version`)
- Public, unauthenticated endpoint returning current release metadata.
- Managed via environment variables or lightweight database configuration.

### 2. Frontend Version Check Service (`AppUpdateService`)
- On startup / resume, parses package version using `package_info_plus`.
- Compares semantic version (`major.minor.patch`).
- If `installed_version < latest_public_version`:
  - Renders non-intrusive `AppUpdateDialog` with changelog and `Update Now` CTA.

### 3. APK Downloader & Installer
- Downloads new APK to application cache storage.
- Invokes native Android package installer intent via `ota_update` / `open_file`.
- Preserves all local `SharedPreferences`, `FlutterSecureStorage`, and database sessions.

---

# TS-009 Email Verification & OTP Specification

## Architecture

```text
User Registers (POST /api/v1/auth/register)
         ↓
Generate Secure 6-Digit OTP (Stored in cache / DB with 10m TTL)
         ↓
Dispatch Email via SMTP (Gmail App Password) / Resend API
         ↓
User Enters OTP (POST /api/v1/auth/verify-otp)
         ↓
Match Code → Set user.is_email_verified = True
         ↓
Issue Active Session Tokens (JWT)
```

## Database Schema Additions (`email_verifications` table)
```sql
CREATE TABLE IF NOT EXISTS email_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_email_verifications_email ON email_verifications(email);
```

## API Endpoints Contract
- `POST /api/v1/auth/verify-otp`: `{ "email": "...", "otp": "123456" }` $\to$ Returns JWT tokens.
- `POST /api/v1/auth/resend-otp`: `{ "email": "..." }` $\to$ 60-second rate-limited resend.

---

# TS-010 Native One-Tap Google Sign-In Architecture

## Architecture

```text
Flutter App (Android / Web)
         ↓  (User taps "Continue with Google")
GoogleSignIn.signIn() -> Native Account Selector Bottom Sheet
         ↓
Retrieve Google `idToken`
         ↓
POST /api/v1/auth/google  { "id_token": "<JWT>" }
         ↓
Backend verify_oauth2_token(id_token, GoogleClientId)
         ↓
Extract Email, Full Name, Avatar URL
         ↓
Upsert User (auth_provider="google", is_email_verified=True)
         ↓
Issue Priora Access & Refresh JWT Tokens
```

## Security & Implementation Details
- **Google Cloud Console:** Configure Android OAuth 2.0 Client (with SHA-1 fingerprint) and Web OAuth 2.0 Client.
- **Backend Verification:** `google.oauth2.id_token.verify_oauth2_token(id_token, requests.Request(), GOOGLE_CLIENT_ID)`.
- **Cost:** Free unlimited usage.

## Dual Authentication Flow Rule (Strict Standard)

```text
┌─────────────────────────────────────────────────────────────┐
│                 Dual Authentication Flows                   │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
       [ Email Signup ]                [ Google Signup ]
               ↓                               ↓
       Generate 6-Digit OTP            Google ID Token Verified
               ↓                               ↓
       User Inputs OTP                 is_email_verified = True
               ↓                               (Automatically)
       is_email_verified = True                ↓
               ↓                       Active Session (Zero OTP)
       Active Session
```

- **Email / Password Signup:** OTP verification is strictly required before issuing active session tokens.
- **Google OAuth Signup:** Automatically marked `is_email_verified = True`. **Never send OTP** to Google-authenticated users, ensuring zero friction and standard industry compliance.

---

# TS-011 Backend Health Ping & Cold-Start Resilience Engine

## Objective
Prevent client timeouts, broken session states, and false network error screens when the Render free-tier backend spins up from an idle cold state.

## Recommended User Flow & Architecture

```text
App Launch (main.dart)
         ↓
Splash Screen (App Icon + Ambient Glow)
         ↓
Check Local Session (FlutterSecureStorage JWT)
         ↓
Background Health Ping: GET /health (Retry loop with 2s interval)
         ↓
If Backend Sleeping:
    Display warming animation with human-friendly progress
         ↓
Backend Spins Up & Responds (HTTP 200 { "status": "healthy" })
         ↓
Load User Profile & Tasks
         ↓
Navigate to Planner Home Screen (/planner) or Login (/login)
```

## Technical Specifications

### 1. Dio Timeout Configuration
- Set `connectTimeout` to **45s** to comfortably accommodate Render cold-start latency.
- Set `receiveTimeout` to **45s**.

### 2. Client-Side Health Watcher Service (`ServerWarmupService`)
- On startup, `ServerWarmupService.ensureServerAwake()` pings `/health`.
- While waiting, updates UI with human-centered, relatable status messages:
  - **0–5s:** *"Preparing your workspace..."*
  - **5–20s:** *"Syncing your tasks..."*
  - **20s+:** *"Almost ready..."*

### 3. Safety Timeout & Fallback Actions (45–60 Seconds)
- If the server does not respond within 45–60 seconds, gracefully stop the loading loop and display:
  > **"We're taking a bit longer than expected."**  
  > `[ Try Again ]` &nbsp;&nbsp;&nbsp;&nbsp; `[ Continue Offline ]`
- **Try Again:** Restarts the health check cycle.
- **Continue Offline:** Enters the app in offline mode using local cache without crashing or logging out.

### 4. Session State Protection
- Prevents `AuthController` from declaring the user "logged out" simply because an initial request encountered a cold-start latency delay.

---

# Priora v1.1.0 Zero-Disruption Compatibility Policy (10 Golden Rules)

### Rule 1: Existing Users Must Continue Without Reinstalling
If a user stays on `v1.0.0` and the backend upgrades to `v1.1.0`, their app must continue to:
- ✅ Login & authenticate
- ✅ View & filter tasks
- ✅ Create & edit tasks
- ✅ Receive notification reminders
- ✅ Sync data without crashes or forced logouts

### Rule 2: Database Changes Must Be Additive Only
- **Allowed:** `ALTER TABLE ADD COLUMN` with default values, `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`.
- **Forbidden:** `DROP COLUMN`, `RENAME COLUMN`, `ALTER COLUMN TYPE`, deleting tables or relationships.
- *v1.1.0 Scope:* `email_verifications` table (new), `app_versions` table (new), Google auth fields (additive).

### Rule 3: New API Fields Must Be Optional
- All new response and request fields (`repeat_type`, `repeat_interval`, `avatar_url`, etc.) must be optional with sensible defaults so `v1.0.0` clients safely ignore them without deserialization errors.

### Rule 4: OTP Verification Must Not Lock Existing Users
- Apply OTP verification strictly to **new registrations** created after v1.1.0 launch.
- Existing accounts created prior to v1.1.0 are grandfathered (`is_email_verified = True`) and must never be blocked from logging in.

### Rule 5: Google Sign-In Must Not Affect Password Users
- Email + password authentication remains 100% active and supported. Google Sign-In is strictly an additional convenience option.

### Rule 6: In-App Update Checker Must Be Opt-In
- Users must always be able to dismiss update alerts via `Later` unless `force_update: true` is explicitly configured on the backend for a critical security patch.

### Rule 7: Server Warming Must Never Block Forever
- Splash screen health polling must have a strict 45–60s safety timeout with `[Try Again]` and `[Continue Offline]` fallbacks to prevent infinite loading screens.

### Rule 8: Notification System Is Frozen
- The validated notification engine (`priora_reminders` channel, raw WAV chimes, foreground receivers, and release shrinker settings) is in **Strict Feature Freeze** to preserve 100% reliability.

### Rule 9: Session & Token Immortality
- Active JWT access and refresh tokens stored in client `FlutterSecureStorage` must remain valid across backend deployments without forcing re-login.

### Rule 10: Bi-Directional Version Safety
- Tasks created or edited on `v1.1.0` clients (with recurrence attributes) must safely render and operate as standard tasks when viewed on older `v1.0.0` clients.

---

*End of Document*
