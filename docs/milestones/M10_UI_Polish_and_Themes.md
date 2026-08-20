# 🎨 Milestone 10 — UI Polish, Themes & Settings System

> **Status:** `IN_PROGRESS`  
> **Target:** Theme Engine, Accent Palette, Reduce Motion, AppEmptyView / AppErrorView, Settings & Storage Usage

---

## 📌 Executive Summary

Milestone 10 delivers a state-of-the-art UI refinement across Priora. It introduces a dynamic **Theme Engine** supporting Light Mode, Dark Mode, System Default, and 5 accent color themes (Indigo, Blue, Green, Orange, Purple), a **Reduce Motion accessibility setting**, unified **`AppEmptyView` and `AppErrorView`** components across all screens, and a dedicated **Settings Screen**.

---

## 🎯 Key Features & Requirements

### 1. Theme & Accent Engine (`ThemeController`)
- **Theme Modes:** `ThemeMode.light`, `ThemeMode.dark`, `ThemeMode.system`.
- **Accent Palette (`AppAccentColor`):** Indigo (`#6366F1`), Blue (`#2563EB`), Green (`#059669`), Orange (`#EA580C`), Purple (`#7C3AED`).
- **Persistent Selection:** Persists `theme_mode`, `theme_accent`, and `reduce_motion` via `SharedPreferences`.

### 2. Accessibility & Motion Controls (`reduce_motion`)
- Toggle switch in Settings to disable shimmers, particle bursts, and spring animations for users preferring minimal motion.

### 3. Reusable UI Components
- **`AppEmptyView`:** Standardized empty state widget with icon, title, message, and CTA button.
- **`AppErrorView`:** Standardized error state widget with retry action.

### 4. Settings Screen (`/settings`)
- Mode Switcher & 5 Accent Color pills.
- Accessibility Reduce Motion toggle.
- Data & Storage usage summary (`storage_used_bytes`, task count, goal count).
- App Version card (`Priora v1.0.0 Build 100`).
- Notification preferences explicitly marked as `(Coming Soon in M11)`.
- Session Log Out button.

---

## 🧪 Testing Criteria
- **Unit & Widget Tests:** `ThemeController` persistence test, `AppAccentColor` theme builder test, `SettingsScreen` widget test.
- **Visual Compliance:** 100% text contrast compliance across all 5 accent palettes in both Light and Dark modes.
