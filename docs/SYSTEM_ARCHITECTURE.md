# Priora — System Architecture & Component Design

> **Version:** v1.0.0 (Build 100 / RC1 Approved)  
> **Status:** Finalized & Implemented  

---

## 1. High-Level Architecture Overview

Priora uses a clean, decoupled client-server architecture. The frontend mobile client is built with **Flutter**, using **Riverpod** for reactive state management and **GoRouter** for shell navigation. The backend service is built with **FastAPI**, leveraging **SQLAlchemy 2.0 (Async)** and **PostgreSQL** for persistence.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER MOBILE CLIENT                            │
│                                                                         │
│  ┌───────────────────────┐   ┌───────────────────┐   ┌───────────────┐  │
│  │   GoRouter Shell      │   │  Riverpod State   │   │ Local Notif   │  │
│  │ (/planner, /tasks...) │◄──┤ Controllers       │◄──┤ Service (v5)  │  │
│  └───────────┬───────────┘   └─────────┬─────────┘   └───────┬───────┘  │
└──────────────┼─────────────────────────┼─────────────────────────┼──────┘
               │ HTTP REST               │ Bearer JWT              │ Native MethodChannel
               ▼                         ▼                         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          FASTAPI BACKEND SERVICE                        │
│                                                                         │
│  ┌───────────────────────┐   ┌───────────────────┐   ┌───────────────┐  │
│  │  API Routers          │   │ Service Layer     │   │ SQLAlchemy    │  │
│  │  (/api/v1/*)          ├──►│ (Business Logic)  ├──►│ Async Models  │  │
│  └───────────────────────┘   └───────────────────┘   └───────┬───────┘  │
└──────────────────────────────────────────────────────────────┼──────────┘
                                                               │ Asyncpg
                                                               ▼
                                                     ┌──────────────────┐
                                                     │ POSTGRESQL DB    │
                                                     └──────────────────┘
```

---

## 2. Frontend Component Architecture

### A. Navigation & Shell Routing (`GoRouter`)
- **ShellRoute Scaffold:** Wraps all protected routes (`/planner`, `/tasks`, `/goals`, `/analytics`, `/review`, `/settings`) inside `MainScaffold`.
- **Persistent Bottom Navigation:** Maintains tab state without rebuilding the page widget tree.
- **Home Landing Route:** Defaults to `/planner` with `index: 0` selected on launch and post-login.

### B. State Management Layer (`Riverpod`)
- **`authControllerProvider`:** Manages authentication lifecycle, JWT token persistence in `FlutterSecureStorage`, and user state.
- **`plannerControllerProvider`:** Controls daily/weekly plan loading, date selection in calendar strip, virtual time-block session creation/editing, and task completion.
- **`tasksControllerProvider`:** Manages task lists, category filtering, search queries, creation/edition bottom sheets, and smart urgency alerts.
- **`notificationSettingsProvider`:** Manages live preference switches for deadline reminders, evening reviews, and goal milestone alerts.

### C. Native Notification Architecture (`local_notification_service.dart`)
- **Plugin Registration:** Initializes `FlutterLocalNotificationsPlugin` with `@mipmap/ic_launcher` icon.
- **Android Channel Configuration (`priora_reminders_v5`):**
  - `importance: Importance.max`
  - `priority: Priority.max`
  - `category: AndroidNotificationCategory.reminder`
  - `audioAttributesUsage: AudioAttributesUsage.notification`
  - `vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000])`
- **Native MethodChannels (`MainActivity.kt`):**
  - `openBatteryOptimizationPrompt`: Launches Android `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
  - `isBatteryOptimizationIgnored`: Invokes `PowerManager.isIgnoringBatteryOptimizations(packageName)` and logs cat trace (`PrioraBattery`).
  - `openExactAlarmSetting`: Deep links to `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`.

---

## 3. R8 / ProGuard Release Shrinker Configuration

To prevent production release APK crashes caused by code shrinking and obfuscation, `frontend/android/app/proguard-rules.pro` enforces strict keep rules:

```proguard
# Preserve generic signatures for Gson TypeToken deserialization in flutter_local_notifications
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod, InnerClasses

# Keep Gson TypeToken and serialization classes
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keepclassmembers class * extends com.google.gson.TypeToken { *; }

# Keep flutter_local_notifications plugin receivers and models
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
```

---

## 4. Backend Service & Data Flow Architecture

- **FastAPI Router Handlers:** Modular route definitions in `app/api/v1/`.
- **Async Service Layer:** Enforces domain logic, permission checks, and transaction management (`app/services/`).
- **SQLAlchemy 2.0 Async Session Management:** Manages asynchronous database queries via `AsyncSession` context managers.
- **Pydantic Validation Schemas:** Strict type parsing and validation for request payloads and JSON responses (`app/schemas/`).
