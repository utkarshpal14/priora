import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

from sqlalchemy.orm import Session

from app.models.task import Task
from app.repositories.analytics_repository import analytics_repository
from app.schemas.task import TaskPriority, TaskStatus
from app.schemas.analytics import (
    AnalyticsBreakdownRead,
    AnalyticsHeatmapRead,
    AnalyticsOverviewRead,
    CategoryBreakdownItem,
    CompletionStatsRead,
    FocusTimeRead,
    GoalAnalyticsRead,
    HeatmapDayItem,
    PersonalRecordsRead,
    PriorityBreakdown,
    ProductivityInsightsRead,
    StreakInfo,
    TimeOfDayBreakdown,
    WeeklyAnalyticsRead,
    WeeklyVelocityDay,
)


class AnalyticsService:
    def get_overview(
        self,
        db: Session,
        user_id: uuid.UUID,
        days: int = 30,
        tz_offset: int = 0,
    ) -> AnalyticsOverviewRead:
        """Compute full overview analytics for user."""
        all_tasks = analytics_repository.get_all_tasks(db, user_id)
        completed_tasks = [t for t in all_tasks if t.status == TaskStatus.COMPLETED and t.completed_at is not None]

        # Convert timestamps to user local dates
        tz_delta = timedelta(minutes=tz_offset)
        now_utc = datetime.now(UTC)
        local_now = now_utc + tz_delta
        today_date = local_now.date()

        # Group completed tasks by local date
        daily_completed_map: dict[str, list[Task]] = {}
        for t in completed_tasks:
            local_dt = t.completed_at + tz_delta if t.completed_at.tzinfo else (t.completed_at.replace(tzinfo=UTC) + tz_delta)
            ldate_str = local_dt.date().isoformat()
            daily_completed_map.setdefault(ldate_str, []).append(t)

        # Calculate Streaks & Personal Best Records
        sorted_dates = sorted([datetime.fromisoformat(d).date() for d in daily_completed_map.keys()])
        
        current_streak = 0
        longest_streak = 0
        best_day_tasks = 0
        best_day_focus_minutes = 0

        for dstr, tasks_list in daily_completed_map.items():
            cnt = len(tasks_list)
            focus_mins = sum(t.estimated_minutes or 30 for t in tasks_list)
            if cnt > best_day_tasks:
                best_day_tasks = cnt
            if focus_mins > best_day_focus_minutes:
                best_day_focus_minutes = focus_mins

        if sorted_dates:
            # Streak calculation: check from today or yesterday backwards
            check_date = today_date
            if check_date.isoformat() not in daily_completed_map:
                check_date = today_date - timedelta(days=1)

            temp_streak = 0
            curr_check = check_date
            while curr_check.isoformat() in daily_completed_map:
                temp_streak += 1
                curr_check -= timedelta(days=1)
            current_streak = temp_streak

            # Longest streak calculation across all historical dates
            temp_max = 0
            curr_max = 0
            prev_d = None
            for d in sorted_dates:
                if prev_d is None or d == prev_d + timedelta(days=1):
                    curr_max += 1
                else:
                    curr_max = 1
                if curr_max > temp_max:
                    temp_max = curr_max
                prev_d = d
            longest_streak = max(temp_max, current_streak)

        # Focus Time calculation (Today, Week 7d, Month 30d)
        week_start_date = today_date - timedelta(days=6)
        month_start_date = today_date - timedelta(days=29)

        today_minutes = 0
        week_minutes = 0
        month_minutes = 0

        for t in completed_tasks:
            local_dt = t.completed_at + tz_delta if t.completed_at.tzinfo else (t.completed_at.replace(tzinfo=UTC) + tz_delta)
            ldate = local_dt.date()
            mins = t.estimated_minutes or 30

            if ldate == today_date:
                today_minutes += mins
            if ldate >= week_start_date:
                week_minutes += mins
            if ldate >= month_start_date:
                month_minutes += mins

        # Add session focus time logged in TaskSession table
        start_utc_today = datetime.combine(today_date, datetime.min.time()) - tz_delta
        start_utc_week = datetime.combine(week_start_date, datetime.min.time()) - tz_delta
        start_utc_month = datetime.combine(month_start_date, datetime.min.time()) - tz_delta

        today_minutes += analytics_repository.get_task_sessions_minutes(db, user_id, start_utc_today, now_utc)
        week_minutes += analytics_repository.get_task_sessions_minutes(db, user_id, start_utc_week, now_utc)
        month_minutes += analytics_repository.get_task_sessions_minutes(db, user_id, start_utc_month, now_utc)

        # Goal & Milestone summary
        goals_data = analytics_repository.get_goals_and_milestones_stats(db, user_id)

        # Productivity Insights (Most Productive Day of Week & Time Window)
        day_counts: dict[str, int] = {}
        window_counts = {"Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0}

        for t in completed_tasks:
            local_dt = t.completed_at + tz_delta if t.completed_at.tzinfo else (t.completed_at.replace(tzinfo=UTC) + tz_delta)
            day_name = local_dt.strftime("%A")
            day_counts[day_name] = day_counts.get(day_name, 0) + 1

            hour = local_dt.hour
            if 6 <= hour < 12:
                window_counts["Morning"] += 1
            elif 12 <= hour < 18:
                window_counts["Afternoon"] += 1
            elif 18 <= hour < 24:
                window_counts["Evening"] += 1
            else:
                window_counts["Night"] += 1

        most_productive_day = max(day_counts.keys(), key=lambda k: day_counts[k]) if day_counts else "N/A"
        most_productive_window = max(window_counts.keys(), key=lambda k: window_counts[k]) if completed_tasks else "N/A"
        window_pct = (window_counts[most_productive_window] / len(completed_tasks) * 100.0) if completed_tasks and most_productive_window != "N/A" else 0.0

        # Completion Stats & On-Time Ratio
        total_tasks = len(all_tasks)
        total_completed = len(completed_tasks)
        overall_completion_rate = (total_completed / total_tasks * 100.0) if total_tasks > 0 else 0.0

        on_time_count = 0
        overdue_count = 0
        for t in completed_tasks:
            if t.deadline:
                if t.completed_at <= t.deadline:
                    on_time_count += 1
                else:
                    overdue_count += 1
            else:
                on_time_count += 1

        on_time_rate = (on_time_count / total_completed * 100.0) if total_completed > 0 else 0.0
        overdue_rate = (overdue_count / total_completed * 100.0) if total_completed > 0 else 0.0

        return AnalyticsOverviewRead(
            streaks=StreakInfo(
                current_streak=current_streak,
                longest_streak=longest_streak,
            ),
            personal_records=PersonalRecordsRead(
                best_day_tasks=best_day_tasks,
                best_day_focus_minutes=best_day_focus_minutes,
                longest_streak=longest_streak,
            ),
            goals_summary=GoalAnalyticsRead(**goals_data),
            focus_time=FocusTimeRead(
                today_minutes=today_minutes,
                week_minutes=week_minutes,
                month_minutes=month_minutes,
            ),
            productivity_insights=ProductivityInsightsRead(
                most_productive_day=most_productive_day,
                most_productive_window=most_productive_window,
                most_productive_window_percentage=round(window_pct, 1),
            ),
            completion_stats=CompletionStatsRead(
                total_completed_tasks=total_completed,
                total_due_tasks=total_tasks,
                overall_completion_rate=round(overall_completion_rate, 1),
                on_time_completion_rate=round(on_time_rate, 1),
                overdue_completion_rate=round(overdue_rate, 1),
            ),
        )

    def get_weekly(
        self,
        db: Session,
        user_id: uuid.UUID,
        days: int = 7,
        tz_offset: int = 0,
    ) -> WeeklyAnalyticsRead:
        """Compute velocity and daily completion rate trends for past N days."""
        all_tasks = analytics_repository.get_all_tasks(db, user_id)
        tz_delta = timedelta(minutes=tz_offset)
        local_today = (datetime.now(UTC) + tz_delta).date()

        days_list: list[WeeklyVelocityDay] = []
        time_of_day = {"morning": 0, "afternoon": 0, "evening": 0, "night": 0}

        for i in range(days - 1, -1, -1):
            target_date = local_today - timedelta(days=i)
            target_str = target_date.isoformat()
            day_label = target_date.strftime("%a")

            completed_count = 0
            completed_mins = 0
            total_due_count = 0

            for t in all_tasks:
                # Check if task was due/scheduled on target_date
                task_date = None
                if t.scheduled_start:
                    task_date = (t.scheduled_start + tz_delta if t.scheduled_start.tzinfo else (t.scheduled_start.replace(tzinfo=UTC) + tz_delta)).date()
                elif t.deadline:
                    task_date = (t.deadline + tz_delta if t.deadline.tzinfo else (t.deadline.replace(tzinfo=UTC) + tz_delta)).date()

                if task_date == target_date:
                    total_due_count += 1

                if t.status == TaskStatus.COMPLETED and t.completed_at:
                    cdate = (t.completed_at + tz_delta if t.completed_at.tzinfo else (t.completed_at.replace(tzinfo=UTC) + tz_delta)).date()
                    if cdate == target_date:
                        completed_count += 1
                        completed_mins += (t.estimated_minutes or 30)

                        hour = (t.completed_at + tz_delta if t.completed_at.tzinfo else (t.completed_at.replace(tzinfo=UTC) + tz_delta)).hour
                        if 6 <= hour < 12:
                            time_of_day["morning"] += 1
                        elif 12 <= hour < 18:
                            time_of_day["afternoon"] += 1
                        elif 18 <= hour < 24:
                            time_of_day["evening"] += 1
                        else:
                            time_of_day["night"] += 1

            comp_rate = (completed_count / total_due_count * 100.0) if total_due_count > 0 else (100.0 if completed_count > 0 else 0.0)
            days_list.append(
                WeeklyVelocityDay(
                    date=target_str,
                    day_label=day_label,
                    completed_count=completed_count,
                    total_due_count=max(total_due_count, completed_count),
                    completion_rate=round(comp_rate, 1),
                    completed_minutes=completed_mins,
                )
            )

        return WeeklyAnalyticsRead(
            days=days_list,
            time_of_day_breakdown=TimeOfDayBreakdown(**time_of_day),
        )

    def get_breakdown(
        self,
        db: Session,
        user_id: uuid.UUID,
        days: int = 30,
        tz_offset: int = 0,
    ) -> AnalyticsBreakdownRead:
        """Compute category and priority distribution for completed tasks."""
        cat_data = analytics_repository.get_category_breakdown(db, user_id)
        prio_data = analytics_repository.get_priority_breakdown(db, user_id)

        total_cat_tasks = sum(item["count"] for item in cat_data)
        categories: list[CategoryBreakdownItem] = []
        for item in cat_data:
            pct = (item["count"] / total_cat_tasks * 100.0) if total_cat_tasks > 0 else 0.0
            categories.append(
                CategoryBreakdownItem(
                    category_id=item["category_id"],
                    name=item["name"],
                    color=item["color"],
                    count=item["count"],
                    percentage=round(pct, 1),
                )
            )

        return AnalyticsBreakdownRead(
            categories=categories,
            priorities=PriorityBreakdown(
                critical=prio_data.get(TaskPriority.CRITICAL, 0),
                high=prio_data.get(TaskPriority.HIGH, 0),
                medium=prio_data.get(TaskPriority.MEDIUM, 0),
                low=prio_data.get(TaskPriority.LOW, 0),
            ),
        )

    def get_heatmap(
        self,
        db: Session,
        user_id: uuid.UUID,
        days: int = 30,
        tz_offset: int = 0,
    ) -> AnalyticsHeatmapRead:
        """Compute GitHub-style activity contribution heatmap for past N days."""
        completed_tasks = analytics_repository.get_completed_tasks(db, user_id)
        tz_delta = timedelta(minutes=tz_offset)
        local_today = (datetime.now(UTC) + tz_delta).date()

        date_count_map: dict[str, int] = {}
        for t in completed_tasks:
            ldate = (t.completed_at + tz_delta if t.completed_at.tzinfo else (t.completed_at.replace(tzinfo=UTC) + tz_delta)).date().isoformat()
            date_count_map[ldate] = date_count_map.get(ldate, 0) + 1

        heatmap_items: list[HeatmapDayItem] = []
        for i in range(days - 1, -1, -1):
            target_date = local_today - timedelta(days=i)
            target_str = target_date.isoformat()
            cnt = date_count_map.get(target_str, 0)

            # Intensity levels: 0 (0), 1 (1-2), 2 (3-4), 3 (5-6), 4 (7+)
            level = 0
            if cnt >= 7:
                level = 4
            elif cnt >= 5:
                level = 3
            elif cnt >= 3:
                level = 2
            elif cnt >= 1:
                level = 1

            heatmap_items.append(HeatmapDayItem(date=target_str, count=cnt, level=level))

        return AnalyticsHeatmapRead(heatmap=heatmap_items)


analytics_service = AnalyticsService()
