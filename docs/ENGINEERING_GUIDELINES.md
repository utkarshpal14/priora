# Priora — Engineering Guidelines & Development Standards

> **Version:** v1.0.0 (Build 100 / RC1 Approved)  
> **Status:** Active Standard  

---

## 1. Flutter Frontend Coding Standards

### State Management & Controller Patterns
- **Use Riverpod Exclusively:** State management must use `StateNotifierProvider` or `NotifierProvider`. Do not use `setState` for non-transient global app state.
- **Widget Binding Safety:** When triggering async side-effects inside `initState` or lifecycle observers (e.g. `_refreshHealthStatus()`), always check `mounted` before executing `setState`:
  ```dart
  if (mounted) {
    setState(() => _isChecking = false);
  }
  ```
- **Timeout Protection:** Platform channel calls (`MethodChannel`) that may stall on un-mocked environments must be wrapped with `.timeout()`:
  ```dart
  final isIgnored = await notifService
      .isBatteryOptimizationIgnored()
      .timeout(const Duration(milliseconds: 300), onTimeout: () => false);
  ```

### Null Safety & Asset Usage
- **No Hardcoded Dynamic Offsets:** UI elements must compute container bounds dynamically rather than using static pixel offsets.
- **Resource Naming:** All raw Android sound files (`priora_alert.wav`) must use lowercase snake_case naming without spaces or special characters.

---

## 2. Release & Shrinker Rules (Android R8 / ProGuard)

When compiling release APKs (`flutter build apk --release`), R8 shrinks and obfuscates unused code. To prevent reflection crashes during background notification execution:
1. **Never Disable ProGuard Without Reason:** Keep `proguard-rules.pro` active and maintain rules for external JSON deserializers (Gson, TypeToken).
2. **Preserve Method & Signature Attributes:**
   ```proguard
   -keepattributes Signature
   -keepattributes *Annotation*
   -keep class com.google.gson.** { *; }
   -keep class com.dexterous.flutterlocalnotifications.** { *; }
   ```

---

## 3. Backend Guidelines (FastAPI & SQLAlchemy)

- **Asynchronous Operations Only:** All DB operations must use `AsyncSession` with `await` syntax (`select()`, `scalars()`, `commit()`).
- **Pydantic Model Schema Separation:** Never expose raw SQLAlchemy ORM models directly in API responses. Map models through Pydantic schemas.
- **Cascade Deletes:** Foreign keys targeting parent entities (`users.id`, `tasks.id`) must specify explicit `ondelete="CASCADE"`.

---

## 4. Git & Release Workflow

1. **Commit Message Format:** Follow Conventional Commits:
   - `feat(planner): ...`
   - `fix(notifications): ...`
   - `docs(qa): ...`
2. **Pre-Release Checklist:**
   - Execute `flutter analyze` (Zero compilation errors).
   - Execute `flutter test` (100% test suite passing).
   - Verify release APK build (`flutter build apk --release`).
