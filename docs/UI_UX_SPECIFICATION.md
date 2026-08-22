# Priora — UI/UX Specification & Navigation Architecture

> **Version:** v1.0.0 (Build 100 / RC1 Approved)  
> **Status:** Finalized & Implemented  

---

## 1. Design System & Typography Tokens

Priora's UI implements a modern, high-contrast, premium aesthetic with smooth micro-animations.

### Color Tokens & Palette
- **Primary Color:** `#2563EB` (Priora Blue)
- **Secondary Accent:** `#7C3AED` (Deep Violet)
- **Background Light:** `#F8FAFC` (Slate 50)
- **Background Dark:** `#0F172A` (Slate 900)
- **Surface Dark:** `#1E293B` (Slate 800)
- **Text Primary Light / Dark:** `#0F172A` / `#FFFFFF`
- **Text Secondary Light / Dark:** `#475569` / `#94A3B8`
- **Error Red:** `#DC2626`
- **Success Green:** `#16A34A`
- **Warning Amber:** `#D97706`

### Typography Scale (Google Fonts Inter)
- **Header Large:** `26px`, Weight `700`, Letter Spacing `-0.5px`
- **Section Title:** `18px`, Weight `700`
- **Card Title:** `14.5px`, Weight `600`
- **Body Text:** `13px`, Weight `400` / `500`
- **Badge & Label:** `11.5px`, Weight `600` / `700`

---

## 2. Navigation Architecture (`GoRouter` + `MainScaffold`)

### Shell Route Structure
All protected application screens render inside a persistent shell scaffold (`MainScaffold`) containing the bottom navigation bar:

```
App Shell (MainScaffold)
│
├── 📅 1. Planner Tab (/planner) [DEFAULT LANDING TAB, index: 0]
│   └── Header Actions: Refresh Plan, Settings & Diagnostics, Log Out
│
├── 📝 2. Tasks Tab (/tasks) [index: 1]
│   └── Filter Chips, Search Bar, Task List, Smart Urgency Banner
│
├── 🎯 3. Goals Tab (/goals) [index: 2]
│   └── Goal Cards, Sub-Goal Checklists, Target Date Progress
│
└── 📊 4. Analytics Tab (/analytics) [index: 3]
    └── Productivity Charts, Velocity Graphs, Category Distribution
```

---

## 3. Detailed Screen Designs & Flow Rules

### 1. Today's Plan (Planner Screen `/planner`)
- **First-Page Experience:** Visiting `/` or logging in automatically lands on `/planner` with the **Planner** calendar tab highlighted in `MainScaffold`.
- **Top AppBar Actions:**
  - `Refresh` button (`Icons.refresh_rounded`)
  - `Settings` button (`Icons.settings_outlined`) -> Navigates to `/settings`
  - `Log Out` button (`Icons.logout_rounded`, Red accent) -> Displays sign-out confirmation modal.
- **Calendar Strip:** Interactive scrollable strip allowing date selection.
- **Overdue Alert Banner:** Amber/Red alert banner rendered at top if overdue tasks exist.
- **Hourly Timeline Section:** Time blocks with active time line indicator. Tapping an empty slot opens `ScheduleTimeSlotDialog`.
- **Floating Action Button:** `Add to Plan` button at bottom right opening `CreateTaskBottomSheet`.

### 2. System Settings & Health Diagnostics (`UX-003`)
- **Theme Selection Card:** Light, Dark, System Theme chips with accent palette options.
- **UX-003 System Health Card:** Live indicators for `PowerManager.isIgnoringBatteryOptimizations` and `canScheduleExactAlarms`.
- **Diagnostics Buttons:**
  - `Test Alert (5s)` button: Triggers immediate test notification to verify channel audio & vibration.
  - `Battery Prompt` button: Opens native Android battery optimization dialog.
  - `Refresh` button: Re-queries native `PowerManager` status live upon returning from system settings.

### 3. Task Creation & Editing Sheets
- **High-Contrast Input Fields:** Enforces explicit dark/light text styles to eliminate input field contrast issues (`BUG-002`, `BUG-003`).
- **Modal Presentation:** Smooth bottom-sheet presentation with drag handle.
