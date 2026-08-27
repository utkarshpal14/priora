# Priora v1.1.0 Product Requirements Document (PRD)

Version: 1.1.0  
Status: Frozen / Approved (v1.1.0 Baseline)  
Freeze Date: August 25, 2026  
Release Type: Minor Feature & UX Enhancement Release  
Compatibility Target: Fully Backward Compatible with v1.0.0  
Author: Priora Team  

---

# 1. Overview

Priora v1.1.0 focuses on improving user experience, reminder effectiveness, theme consistency, and recurring productivity workflows while maintaining full compatibility with existing v1.0.0 users.

This release must not disrupt any currently installed beta APKs or existing backend functionality.

---

# 2. Release Goals

## Primary Goals

- Improve reminder visibility and effectiveness.
- Fix theme application inconsistencies.
- Improve onboarding professionalism.
- Introduce recurring productivity workflows.
- Maintain 100% backward compatibility.

## Non-Goals

The following are explicitly excluded from v1.1.0:

- AI scheduling
- Calendar synchronization
- Team collaboration
- Web application
- Desktop application
- Push notification infrastructure migration
- Major database redesign

---

# 3. Compatibility Requirements

## Mandatory Requirement

All existing v1.0.0 users must continue operating normally after backend deployment.

### Existing APK Compatibility

The following must never break:

- User authentication
- User registration
- Task creation
- Reminder scheduling
- Goal management
- Category management
- Planner functionality
- Notification delivery

### Database Compatibility

Allowed:

- Add new columns
- Add new tables
- Add indexes

Forbidden:

- Remove existing columns
- Rename existing columns
- Modify existing API contracts

---

# 4. Features

---

# BUG-001: Global Theme Synchronization

## Problem

Currently changing the theme from Settings only updates the Settings page.

The rest of the application remains unchanged.

This creates inconsistent UI behavior.

## Objective

Theme selection must apply globally across the entire application.

## Functional Requirements

When a user changes:

Settings → Theme

The following must update immediately:

- Dashboard
- Planner
- Tasks
- Goals
- Settings
- Navigation Shell
- Dialogs
- Bottom Sheets
- App Bars
- Cards

## Acceptance Criteria

- Theme updates without restarting the app.
- Theme persists after application restart.
- Theme remains synchronized across all screens.

**Priority:** Critical

---

# UX-004: Signup Placeholder Cleanup

## Problem

The signup screen currently contains development placeholder values.

Example:

`Utkarsh Pal`

This appears unprofessional to end users.

## Objective

Replace personal placeholders with production-ready text.

## Requirements

Replace with:

- `Enter your full name`

or

- `Your Name`

## Acceptance Criteria

No personal names appear anywhere in onboarding or authentication flows.

**Priority:** Critical

---

# ENH-004: Enhanced Reminder Audio Alerts

## Problem

Users may miss important reminders due to short default notification sounds.

## Objective

Increase reminder awareness without becoming intrusive.

## Functional Requirements

When a reminder notification triggers:

- Notification appears normally.
- Priora custom alert sound plays.
- Audio duration approximately 3–5 seconds.
- Audio stops automatically.
- User can tap notification immediately.
- Reminder scheduling system remains unchanged.

## Non-Functional Requirements

Must not:

- Loop continuously
- Behave like an alarm clock
- Require manual dismissal

## Acceptance Criteria

- Reminder sound plays successfully.
- Audio automatically stops.
- Existing reminders continue functioning.

**Priority:** High

---

# ENH-005: Recurring Tasks

## Problem

Users repeatedly create the same tasks manually.

Examples:

Students:
- Daily DSA Practice
- Daily Study Session
- Weekly Assignment Review

Professionals:
- Daily Standup
- Weekly Reports
- Monthly Reviews

## Objective

Allow tasks to repeat automatically.

## Functional Requirements

Task Creation Screen shall support:

Repeat:

- `Never`
- `Daily`
- `Weekly`
- `Monthly`

Optional:

- Custom Interval (Future Expansion)

## Reminder Support

Recurring tasks must support reminders.

Examples:

Daily:  
Study DSA  
7:00 PM  

Weekly:  
Project Review  
Monday 8:00 PM  

Monthly:  
Pay Credit Card Bill  
1st Day of Month  

## Task Completion Behavior

Completing a recurring task:

- Marks current occurrence completed.
- Automatically schedules next occurrence.

## Acceptance Criteria

Users no longer need to manually recreate recurring tasks.

**Priority:** High

---

# ENH-006: Recurring Reminder Scheduling

## Objective

Enable reminders to repeat automatically with recurring tasks.

## Requirements

Reminder recurrence options:

- `Daily`
- `Weekly`
- `Monthly`

Reminder schedule must remain synchronized with task recurrence.

## Acceptance Criteria

Recurring reminders continue generating future reminders automatically.

**Priority:** High

---

# 5. User Impact

## Existing Users

**Impact:** None  
Existing APK users should continue operating normally.  
No action required.

## New Users

Benefit from:

- Better reminders
- Improved onboarding
- Global themes
- Recurring task workflows

---

# 6. Technical Constraints

- Backend deployments must remain backward compatible.
- No destructive database migrations allowed.
- Existing API responses must remain valid.
- All new fields must be optional.

---

# 7. Success Metrics

The release will be considered successful when:

- Theme synchronization works globally.
- Reminder sound is reliably noticeable.
- Recurring tasks operate correctly.
- Existing v1.0.0 APK users remain unaffected.
- No authentication regressions occur.
- No notification regressions occur.

---

# 8. Release Strategy

- **Phase 1:** Database additions.
- **Phase 2:** Backend compatibility deployment.
- **Phase 3:** Internal testing.
- **Phase 4:** v1.1.0 APK generation.
- **Phase 5:** Beta distribution.
- **Phase 6:** Feedback collection.

---

# ENH-006: Developer-Controlled In-App Update System

## Problem
When releasing new features or fixes via sideloaded APKs, existing users on older builds do not receive updates automatically because Android OS prevents silent APK binary replacement without user confirmation or a trusted app store. Furthermore, the developer often builds test APKs for personal evaluation and requires strict separation so that private dev/testing builds do not prematurely prompt active users.

## Objective
Provide an in-app update mechanism where existing APK users are notified of new public releases and can update in 1 tap, with complete manual control over when a release is broadcast to users.

## Requirements

### 1. Developer Separation & Control
- Developer can build and test private debug/release APKs at any time without triggering update prompts for users.
- Public updates are broadcast **only** when the developer explicitly updates the public release version on the backend (`latest_public_version`).

### 2. In-App Check & Notification
- On app launch, the client checks the active public release status via `GET /api/v1/system/app-version`.
- If `installed_version < latest_public_version`, the app displays a modern update modal displaying:
  - New version number (e.g. `v1.1.0`)
  - Changelog / Release highlights
  - `Update Now` and `Later` actions

### 3. One-Tap Download & Install
- Tapping `Update Now` downloads the APK and launches the native package installer.
- User data, login tokens, and local settings are 100% preserved during the update.

## Acceptance Criteria
- Private developer builds do not trigger update prompts for public users.
- Updating `latest_public_version` on the backend reliably prompts users on older builds upon launch.
- Sideloaded APKs update smoothly with zero data or session loss.

**Priority:** High (Post-v1.1.0 Candidate / v1.2.0 Delivery)

---

# SEC-004: Email Verification & OTP Verification Gate

## Problem
Users can currently register accounts using non-existent or fake email addresses (e.g., `fake123@gmail.com`). Because there is no active verification step, unverified accounts can log in and store tasks, which compromises data integrity and prevents reliable password resets or critical notifications.

## Objective
Prevent registration with non-existent emails by requiring a verified 6-digit One-Time Password (OTP) or confirmation link before granting access.

## Requirements

### 1. OTP Delivery Service
- Send a 6-digit numeric OTP code upon registration to the user's provided email.
- Utilizes free-tier email delivery (Gmail SMTP with App Password or Resend / SendGrid / Supabase Auth).
- Code expires after a configurable duration (e.g., 10 minutes).

### 2. Verification Gate
- Require the user to input the 6-digit OTP to complete onboarding.
- Set `is_email_verified = True` in the database upon successful verification.
- Block access to tasks and planner until verified (`is_email_verified == True`).

### 3. Resend & Rate Limiting
- Provide a "Resend OTP" button with a 60-second cooldown timer to prevent spamming.

## Acceptance Criteria
- Non-existent emails cannot bypass registration to create active sessions.
- Users receive OTP within 5–10 seconds and can verify seamlessly.
- Existing v1.0.0 users are grandfathered safely without lockouts.

**Priority:** High

---

# AUTH-002: Native One-Tap Google Sign-In

## Problem
Manual email and password entry creates signup friction, increases forgotten password requests, and requires extra verification steps.

## Objective
Allow users to log in or register with a single click using their device's native Google Account.

## Requirements

### 1. Native One-Tap Flow
- Tap "Continue with Google" on Login or Register screen.
- Directly opens Android native Google Account picker bottom sheet or Google Identity Services prompt on Web.

### 2. Token Exchange & Backend Verification
- Frontend retrieves Google ID token and sends it to `POST /api/v1/auth/google`.
- Backend cryptographically verifies the token using Google OAuth 2.0 Client ID (`google.oauth2.id_token.verify_oauth2_token()`).
- Auto-creates user account if new, or logs in if existing.
- Automatically marks `is_email_verified = True` (since Google has verified the Gmail account).
### 3. Verification & Zero-OTP Rule
- Users who authenticate via Google Sign-In are **automatically verified** (`is_email_verified = True`) because Google validates Gmail ownership.
- **Never send OTP codes to Google-authenticated users**, ensuring maximum onboarding speed and zero unnecessary friction.

## Acceptance Criteria
- Single tap signs in within 1–2 seconds with zero password entry required.
- Google OAuth token exchange succeeds securely on both Android and Web.
- Zero OTP codes generated or sent for Google signups.
- Zero cost using free Google Cloud OAuth 2.0 credentials.

---

# UX-005: Cold-Start Server Warming & Graceful Splash Loading

## Problem
Render's free hosting tier spins down instances after 15 minutes of inactivity. When a user opens the app during a cold start, initial HTTP requests can take 30–50 seconds to wake up the server. Previously, if requests timed out prematurely (5–10s), the app could display a broken login state, failed authentication, or empty task errors, making the app appear broken to the user.

## Objective
Provide a polished, human-centered cold-start loading screen upon app launch that gracefully warms up the backend in the background without throwing errors, showing technical jargon, or leaving users stuck indefinitely.

## Recommended User Flow

```text
App Launch
    ↓
Splash Screen (App Icon + Ambient Glow)
    ↓
Check Local Session
    ↓
Ping /health
    ↓
If Backend Sleeping:
    Display warming animation + human-friendly progress
    ↓
Backend Responds (200 OK)
    ↓
Load User & Tasks
    ↓
Navigate to Planner Home Screen (or Login if unauthenticated)
```

## Requirements

### 1. Human-Centered Progress Copy
Instead of technical jargon (like "server" or "cloud"), display relatable, friendly messages:
- **0–5s:** *"Preparing your workspace..."*
- **5–20s:** *"Syncing your tasks..."*
- **20s+:** *"Almost ready..."*

### 2. Background Health Polling
- Client sends a lightweight ping to `GET /health` with automatic retry (2s interval).
- Prevents false-positive network error dialogs, empty red error banners, or accidental logouts while the server spins up.

### 3. Safety Timeout & Fallback Actions (45–60 Seconds)
- If the server does not respond within 45–60 seconds, gracefully stop the loading animation and display a clean recovery view:
  > **"We're taking a bit longer than expected."**  
  > `[ Try Again ]` &nbsp;&nbsp;&nbsp;&nbsp; `[ Continue Offline ]`
- **Try Again:** Restarts the health ping cycle.
- **Continue Offline:** Allows the user into the app using locally cached tasks and offline state.

## Acceptance Criteria
- No technical server jargon is presented to the user.
- Users are never permanently stuck on a frozen loading spinner.
- Timeout safely offers `[ Try Again ]` and `[ Continue Offline ]`.
- Seamless transition occurs automatically the instant the backend is ready.

**Priority:** High

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
