# Priora v1.1.0 Test Plan

Version: 1.1.0  
Status: Frozen / Approved (v1.1.0 Baseline)  
Freeze Date: August 25, 2026  
Testing Type: Functional + Compatibility + Regression  

---

# Objective

Validate all Priora v1.1.0 functionality before release.

Ensure:
- Existing users remain unaffected
- New features work correctly
- No regressions are introduced
- Backend compatibility is preserved

---

# Test Environments

### Environment A
- **Backend:** Production Backend (Render)
- **Database:** Production Database (Supabase)
- **APK Version:** v1.0.0
- **Purpose:** Backward Compatibility Validation

---

### Environment B
- **Backend:** Development Backend (Local)
- **Database:** Development Database (Local PostgreSQL)
- **APK Version:** v1.1.0
- **Purpose:** Feature Validation

---

### Environment C
- **Backend:** Production Backend (Render)
- **Database:** Production Database (Supabase)
- **APK Version:** v1.1.0
- **Purpose:** Pre-Release Validation

---

# Section 1: Authentication Testing

## AUTH-001 Registration
**Steps:**
1. Open App
2. Register New Account

**Expected:**
- ✓ Account created
- ✓ User redirected correctly
- ✓ Database record created

---

## AUTH-002 Login
**Steps:**
1. Login with valid credentials

**Expected:**
- ✓ Login successful
- ✓ JWT generated
- ✓ User session restored

---

## AUTH-003 Invalid Credentials
**Expected:**
- ✓ Proper error shown
- ✓ App remains stable

---

# Section 2: Theme Synchronization

## THEME-001 Global Theme Change
**Steps:**
1. Open Settings
2. Change theme

**Expected:**
- ✓ Dashboard updates
- ✓ Planner updates
- ✓ Tasks update
- ✓ Goals update
- ✓ Settings update
- ✓ Navigation updates

---

## THEME-002 Theme Persistence
**Steps:**
1. Select Dark Theme
2. Close App
3. Reopen App

**Expected:**
- ✓ Dark Theme remains active

---

## THEME-003 Logout/Login
**Expected:**
- ✓ Theme preference preserved

---

# Section 3: Signup Placeholder Validation

## UX-001 Placeholder Check
**Steps:**
1. Open Signup Screen

**Expected:**
- ✓ No personal names visible
- ✓ Placeholder shows: `"Enter your full name"` or `"Your Name"`

---

# Section 4: Reminder Audio Testing

## REM-001 Reminder Notification
**Steps:**
1. Create reminder
2. Wait for trigger

**Expected:**
- ✓ Notification displayed
- ✓ Sound plays
- ✓ Sound audible
- ✓ Sound stops automatically

---

## REM-002 Multiple Reminders
**Expected:**
- ✓ Each reminder plays correctly
- ✓ No overlapping issues

---

## REM-003 Device Restart
**Expected:**
- ✓ Reminder still triggers
- ✓ Sound still plays

---

# Section 5: Recurring Tasks

## REC-001 Daily Task
**Steps:**
1. Create task: "Study DSA"
2. Repeat: "Daily"

**Expected:**
- ✓ Task created
- ✓ Repeat value saved

---

## REC-002 Daily Completion
**Steps:**
1. Complete task

**Expected:**
- ✓ Current occurrence completed
- ✓ Next occurrence generated

---

## REC-003 Weekly Task
**Expected:**
- ✓ Next weekly occurrence created

---

## REC-004 Monthly Task
**Expected:**
- ✓ Next monthly occurrence created

---

## REC-005 Repeat None
**Expected:**
- ✓ No future task generated

---

# Section 6: Recurring Reminders

## RREM-001 Daily Reminder
**Expected:**
- ✓ Reminder recreated automatically

---

## RREM-002 Weekly Reminder
**Expected:**
- ✓ Reminder scheduled correctly

---

## RREM-003 Monthly Reminder
**Expected:**
- ✓ Reminder scheduled correctly

---

# Section 7: Task Management Regression

## TASK-001 Create Task
**Expected:**
- ✓ Works

---

## TASK-002 Edit Task
**Expected:**
- ✓ Works

---

## TASK-003 Complete Task
**Expected:**
- ✓ Works

---

## TASK-004 Delete Task
**Expected:**
- ✓ Works

---

# Section 8: Goal Management Regression

## GOAL-001 Create Goal
**Expected:**
- ✓ Works

---

## GOAL-002 Edit Goal
**Expected:**
- ✓ Works

---

## GOAL-003 Delete Goal
**Expected:**
- ✓ Works

---

# Section 9: Notification Regression

## NOTIF-001 One-Time Reminder
**Expected:**
- ✓ Works

---

## NOTIF-002 Scheduled Reminder
**Expected:**
- ✓ Works

---

## NOTIF-003 App Closed
**Expected:**
- ✓ Notification still delivered

---

## NOTIF-004 Device Reboot
**Expected:**
- ✓ Notification restored

---

# Section 10: Backward Compatibility

## COMP-001 Existing APK
**Environment:**
- v1.0.0 APK + New Backend

**Expected:**
- ✓ Login works
- ✓ Registration works
- ✓ Tasks work
- ✓ Goals work
- ✓ Reminders work
- ✓ No crashes

---

## COMP-002 Existing Database Records
**Expected:**
- ✓ Existing tasks visible
- ✓ Existing reminders visible
- ✓ Existing goals visible

---

## COMP-003 Mixed User Environment
**Expected:**
- ✓ v1.0.0 users supported
- ✓ v1.1.0 users supported

---

# Section 11: Performance Validation

## PERF-001 App Startup
**Expected:**
- ✓ No noticeable slowdown

---

## PERF-002 Task Creation
**Expected:**
- ✓ Under 1 second

---

## PERF-003 Theme Change
**Expected:**
- ✓ Instant update

---

# Release Approval Checklist

Before release:
- [x] All Authentication Tests Pass
- [x] All Theme Tests Pass
- [x] All Reminder Tests Pass
- [x] All Recurring Task Tests Pass
- [x] All Recurring Reminder Tests Pass
- [x] All Compatibility Tests Pass
- [x] No Critical Bugs Open
- [x] Existing v1.0.0 APK Verified

---

# Release Decision

**Release Approved Only If:**
- 100% Critical Tests Pass
- No Data Loss Issues
- No Authentication Issues
- No Notification Failures
- Existing Users Remain Functional

---

*End of Document*
