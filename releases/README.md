# Priora — Release APK Archives

This directory stores version-by-version release APK binaries for easy backup, distribution, and rollback testing.

---

## 📂 Directory Structure

```text
releases/
├── README.md                                # Release archive documentation
├── v1.1.0/
│   └── priora-v1.1.0-release.apk            # Release v1.1.0 (Custom Sounds & Base Updater)
└── v1.1.2/
    └── priora-v1.1.2-release.apk            # Release v1.1.2 (Root Navigator & Settings Checker)
```

---

## 📋 Release Catalog

| Version | Build | APK File | Size | Key Highlights |
| :--- | :---: | :--- | :---: | :--- |
| **`v1.1.2`** | `+3` | [`releases/v1.1.2/priora-v1.1.2-release.apk`](v1.1.2/priora-v1.1.2-release.apk) | ~64.4 MB | • Fixed route transitions auto-dismissing update dialog (`rootNavigatorKey`)<br>• Added **"Check for Updates"** button in Settings Screen<br>• Enhanced Android 13+ permission resume lifecycle |
| **`v1.1.0`** | `+2` | [`releases/v1.1.0/priora-v1.1.0-release.apk`](v1.1.0/priora-v1.1.0-release.apk) | ~64.4 MB | • 6 Custom reminder audio chimes<br>• In-App OTA APK updater engine<br>• Global theme synchronization |

---

## 🛠️ How to Add Future Version Builds

When creating a new release (e.g. `v1.2.0`):

1. Bump `version` in `frontend/pubspec.yaml` (e.g., `1.2.0+4`)
2. Bump `currentInstalledVersion` in `frontend/lib/core/services/app_update_service.dart`
3. Run `flutter build apk --release` in `frontend/`
4. Copy the binary:
   ```powershell
   New-Item -ItemType Directory -Force -Path "releases\v1.2.0"
   Copy-Item -Path "frontend\build\app\outputs\flutter-apk\app-release.apk" -Destination "releases\v1.2.0\priora-v1.2.0-release.apk" -Force
   ```
5. Update this `README.md` catalog.
