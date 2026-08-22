# Milestone 9 — Analytics & Productivity Insights Specification

## 1. Overview
Milestone 9 introduces a comprehensive analytics and data visualization engine to Priora. It transforms raw completion data, task sessions, schedules, deadlines, categories, and goals into actionable productivity metrics, performance streaks, personal records, category breakdowns, and GitHub-style contribution heatmaps.

---

## 2. Core Capabilities & Rule Definitions

### 1. 🔥 Strict Streak Logic Definition
- **Active Day Condition:** A local calendar day (adjusted by user `tz_offset`) is considered **Active** if and only if **at least 1 task** was completed on that day.
- **Streak Calculation:**
  - If today (local) has $\ge 1$ completed task, streak includes today.
  - If today has 0 completed tasks but yesterday (local) had $\ge 1$ completed task, the streak remains intact (allowing today to be completed).
  - If yesterday had 0 completed tasks, the current streak resets to 0 (or 1 if today has $\ge 1$ completed task).

### 2. 🏆 Personal Records (Motivational Highlights)
- **Best Day Ever:** Maximum number of tasks completed in a single local day.
- **Longest Streak:** All-time record consecutive active days.
- **Highest Focus Time Day:** Maximum focus minutes completed in a single local day (e.g. `8h 15m`).

### 3. 🎯 Goal & Milestone Analytics
- **Active Goals Count:** Total goals currently in progress (`status == IN_PROGRESS`).
- **Completed Goals Count:** Total goals marked completed.
- **Goal Completion Rate %:** `(completed_goals / total_goals) * 100`.
- **Milestones Completion Rate %:** `(completed_milestones / total_milestones) * 100`.

### 4. ⏱️ Focus-Time Analytics (Today, Week, Month)
- Integrates both task completed `estimated_minutes` and tracked `TaskSession` durations.
- **Focus Time Today:** Total focus hours & minutes for today.
- **Focus Time This Week:** Total focus hours & minutes for the current 7-day period.
- **Focus Time This Month:** Total focus hours & minutes for the current 30-day period.

### 5. 📈 Completion Rate Trend & Insights
- **Daily Completion Rate Trend (%):** Percentage of completed tasks out of total scheduled/due tasks for each day (e.g. Mon 70%, Tue 80%, Wed 100%).
- **Most Productive Day Insight:** The day of the week with the highest average completions (e.g., "*Most Productive Day: Tuesday*").
- **Most Productive Time Window Insight:** Time window with highest completion volume (e.g., "*Most Productive Window: Evening (42%)*").

---

## 3. Database & Dynamic Aggregation Architecture

- **Zero Database Bloat:** All metrics are aggregated dynamically via optimized SQLAlchemy queries (`func.count`, `func.sum`, date grouping) operating directly on `tasks`, `goals`, `goal_milestones`, and `task_sessions` tables.
- **Timezone Awareness:** All date grouping algorithms accept `tz_offset` parameter to group completion timestamps by the user's local day boundaries.
- **Flexible Date Range Querying:** All endpoint endpoints support optional `days: int` query parameter (`days=7`, `days=30`, `days=90`).

---

## 4. API Endpoints

### 1. `GET /api/v1/analytics/overview`
- **Query Parameters:** `days: int = 30`, `tz_offset: int = 0`
- **Response:**
  ```json
  {
    "streaks": {
      "current_streak": 5,
      "longest_streak": 14
    },
    "personal_records": {
      "best_day_tasks": 12,
      "best_day_focus_minutes": 495,
      "longest_streak": 14
    },
    "goals_summary": {
      "active_goals": 4,
      "completed_goals": 2,
      "goal_completion_rate": 33.3,
      "milestone_completion_rate": 65.0
    },
    "focus_time": {
      "today_minutes": 220,
      "week_minutes": 1100,
      "month_minutes": 4260
    },
    "productivity_insights": {
      "most_productive_day": "Tuesday",
      "most_productive_window": "Evening",
      "most_productive_window_percentage": 42.5
    },
    "completion_stats": {
      "total_completed_tasks": 42,
      "overall_completion_rate": 84.0,
      "on_time_completion_rate": 91.5,
      "overdue_completion_rate": 8.5
    }
  }
  ```

### 2. `GET /api/v1/analytics/weekly`
- **Query Parameters:** `days: int = 7`, `tz_offset: int = 0`
- **Response:**
  ```json
  {
    "days": [
      {
        "date": "2026-08-18",
        "day_label": "Tue",
        "completed_count": 5,
        "total_due_count": 5,
        "completion_rate": 100.0,
        "completed_minutes": 240
      }
    ],
    "time_of_day_breakdown": {
      "morning": 12,
      "afternoon": 15,
      "evening": 22,
      "night": 3
    }
  }
  ```

### 3. `GET /api/v1/analytics/breakdown`
- **Query Parameters:** `days: int = 30`, `tz_offset: int = 0`
- **Response:**
  ```json
  {
    "categories": [
      { "category_id": "cat-1", "name": "Work", "color": "#1E40AF", "count": 15, "percentage": 45.0 }
    ],
    "priorities": {
      "CRITICAL": 5,
      "HIGH": 12,
      "MEDIUM": 15,
      "LOW": 8
    }
  }
  ```

### 4. `GET /api/v1/analytics/heatmap`
- **Query Parameters:** `days: int = 30`, `tz_offset: int = 0`
- **Response:**
  ```json
  {
    "heatmap": [
      { "date": "2026-07-22", "count": 3, "level": 2 }
    ]
  }
  ```

---

## 5. Frontend UI Components (`frontend/lib/features/analytics/`)

1. **`AnalyticsScreen`**: Main scrollable analytics dashboard screen with pull-to-refresh.
2. **`PersonalRecordsCard`**: Highlights Best Day Ever, Longest Streak, and Highest Focus Time.
3. **`GoalAnalyticsCard`**: Visual progress breakdown of Active vs Completed Goals & Milestones.
4. **`FocusTimeSummaryCard`**: Cards displaying Today, Week, and Month focus hours.
5. **`StreakMetricCard`**: 🔥 Interactive flame card with current & record streaks.
6. **`WeeklyVelocityChartWidget`**: 7-day completion velocity & daily completion rate trend (% bar chart).
7. **`CategoryDistributionChart`**: Color-coded category distribution donut chart.
8. **`ActivityHeatmapGridWidget`**: 30-day activity intensity grid.
9. **`ProductivityInsightsWidget`**: Highlights "Most Productive Day" & "Most Productive Time Window".
