# Priora — APK Release & In-App Update Workflow SOP

**Version:** v1.1.0+  
**Target:** Standard Operating Procedure (SOP) for Publishing APK Updates  
**Mechanism:** Developer-Controlled Over-The-Air (OTA) In-App Update System (`ENH-006` / `TS-008`)

---

## 🎯 Overview & Golden Rules

- **Private Testing Isolation:** You can build, test, and install APKs on your phone as much as you want without disturbing active users.
- **Broadcast on Demand:** Active users only receive the update dialog when you explicitly update the version on the backend.
- **Zero Session Loss:** Users update in 1 tap without losing tasks, settings, or login sessions.

---

## 📋 The 4-Step Release Procedure

```text
┌─────────────────────────────────────────────────────────────┐
│ 1. Bump Version in Code (pubspec.yaml & app_update_service)  │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ 2. Build Clean Release APK (flutter build apk --release)     │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ 3. Upload APK to GitHub Releases (Get Direct Download URL)   │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ 4. Flip Backend Switch (Render Env Vars or config.py)        │
└─────────────────────────────────────────────────────────────┘
```

---

### Step 1: Bump the App Version (Single Source of Truth)

1. Open [`frontend/lib/core/constants/app_constants.dart`](file:///c:/Users/Utkarsh%20Pal/Documents/priora/frontend/lib/core/constants/app_constants.dart):
   ```dart
   static const String appVersion = '1.1.2';
   ```
2. Open [`frontend/pubspec.yaml`](file:///c:/Users/Utkarsh%20Pal/Documents/priora/frontend/pubspec.yaml):
   ```yaml
   version: 1.1.2+3
   ```
*(Note: `AppUpdateService.currentInstalledVersion` and the Settings Rocket card dynamically read from `AppConstants.appVersion` automatically).*

---

### Step 2: Build & Archive the Production Release APK

Run these commands:

```powershell
cd frontend
flutter build apk --release

# Archive APK into versioned storage folder
New-Item -ItemType Directory -Force -Path "..\releases\v1.1.2"
Copy-Item -Path "build\app\outputs\flutter-apk\app-release.apk" -Destination "..\releases\v1.1.2\priora-v1.1.2-release.apk" -Force
```

**Local Archive Location:**  
`releases/v1.1.2/priora-v1.1.2-release.apk`

---

### Step 3: Upload the APK (GitHub Releases)

1. Go to your GitHub repository: `https://github.com/utkarshpal14/priora/releases`
2. Click **"Draft a new release"**.
3. Create a tag matching the version (e.g. `v1.1.1`).
4. Rename `app-release.apk` to `priora-v1.1.1-release.apk` and attach it to the release assets.
5. Publish the release and copy the direct APK download URL:  
   *Example:* `https://github.com/utkarshpal14/priora/releases/download/v1.1.1/priora-v1.1.1-release.apk`

---

### Step 4: Broadcast the Update to All Users

You have **two options** to flip the release switch:

#### ⚡ Option A: Instant Broadcast via Render Dashboard (Recommended — No Code Deploy)
1. Open your **Render Dashboard** $\to$ `priora-api` $\to$ **Environment**.
2. Update / Add these Environment Variables:
   - `LATEST_APP_VERSION`: `1.1.1`
   - `APK_DOWNLOAD_URL`: `https://github.com/utkarshpal14/priora/releases/download/v1.1.1/priora-v1.1.1-release.apk`
   - `APP_RELEASE_NOTES`: `• 6 new custom reminder sounds\n• Global dark mode synchronization\n• Recurring tasks & reminders`
   - `FORCE_APP_UPDATE`: `false` *(set `true` only for critical breaking security releases)*
3. Click **Save Changes**. The update broadcasts instantly to all active devices.

#### 🛠️ Option B: Via Code (`backend/app/core/config.py`)
1. In [`backend/app/core/config.py`](file:///c:/Users/Utkarsh%20Pal/Documents/priora/backend/app/core/config.py):
   ```python
   LATEST_APP_VERSION: str = "1.1.1"
   APK_DOWNLOAD_URL: str = "https://github.com/utkarshpal14/priora/releases/download/v1.1.1/priora-v1.1.1-release.apk"
   APP_RELEASE_NOTES: str = "• 6 new custom reminder sounds\n• Global dark mode synchronization\n• Recurring tasks & reminders"
   FORCE_APP_UPDATE: bool = False
   ```
2. Commit and push:
   ```bash
   git add backend/app/core/config.py
   git commit -m "chore(release): bump public version to v1.1.1"
   git push origin main
   ```

---

## 📱 What Users Experience

1. When any user on an older build (`v1.0.0` or `v1.1.0`) opens the app:
2. The app checks `GET /api/v1/system/app-version` and detects that their version is older.
3. The **"Update Available!"** modal pops up displaying your release notes.
4. Tapping **"Update Now"** downloads the APK and prompts the 1-tap Android package installer.
5. All user tasks, local settings, and login sessions are 100% preserved.

---

## 🧪 Private Development & Testing Mode

When developing features for yourself:
- Set `currentInstalledVersion = '1.1.2-dev'` or install locally.
- Leave `LATEST_APP_VERSION = '1.1.0'` on Render.
- **Result:** You test privately on your device while public users see **zero update popups**.

---

*End of SOP*
