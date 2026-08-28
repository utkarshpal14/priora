# Priora Release v1.1.3

**Release Date:** August 29, 2026  
**Binary File:** `priora-v1.1.3-release.apk`  
**Package:** `com.priora.app`  
**Download URL:** `https://github.com/utkarshpal14/priora/releases/download/v1.1.3/priora-v1.1.3-release.apk`

---

## 🌟 Highlights & Major Features

### 1. Enterprise Forgot Password & Password Reset Flow
- **Self-Service Password Recovery:** Users can request a secure 6-digit recovery code from the login screen.
- **Global Session Invalidation:** When a password is reset, `user.token_version += 1` executes, instantly revoking all active JWT access and refresh tokens across all devices.
- **Single Active Code & Expiry:** 10-minute expiry with immediate invalidation of prior codes.
- **Brute-Force Lockout:** Account lockout protection after 5 consecutive incorrect code attempts.
- **Timing-Safe Cooldowns:** Obscures timing information to resist enumeration side-channel attacks.

### 2. Transactional Email Delivery via `verify@priorapp.co.in`
- **Branded Sender:** Configured custom domain with live Resend HTTPS transactional dispatch.
- **Dark & Gold Email Template:** High-visibility OTP codes and explicit security warnings.

### 3. Email OTP Account Verification
- Hashed 6-digit OTP verification upon registration with zero plain-text storage.
- Auto-activation and backwards-compatible zero-lockout login for existing users.

### 4. Google OAuth 2.0 Integration
- One-tap Google Sign-In with automated user profile provisioning.

### 5. Smart Notifications & Custom Audio Chimes
- 6 custom notification chimes for task deadlines, morning planning, and evening reviews.
- Battery optimization and exact alarm permission management.

---

## 🔒 Security & Verification
- **Automated Tests:** 75/75 Backend tests passing (`pytest`), 55/55 Flutter tests passing (`flutter test`).
- **Database Schema Sync:** Automatic startup column migrations on SQLite and PostgreSQL.
- **SHA-256 Checksum:** Available in `releases/v1.1.3/priora-v1.1.3-release.apk.sha256`.
