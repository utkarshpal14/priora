import uuid
from datetime import UTC, date, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.task import Task
from app.schemas.planner import (
    DailyPlanRead,
    DayPlanSummary,
    TimelineBucket,
    WeeklyPlanDay,
    WeeklyPlanRead,
)
from app.schemas.task import TaskPriority, TaskRead, TaskStatus


def _to_utc(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt.astimezone(UTC)


class PlannerService:
    """Service coordinating daily and weekly timeline planning logic."""

    def _get_composite_score(self, task: Task, now_utc: datetime) -> int:
        deadline_utc = _to_utc(task.deadline)
        is_overdue = (
            deadline_utc is not None
            and deadline_utc < now_utc
            and task.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)
        )
        priority = task.priority.upper()

        if is_overdue:
            if priority == TaskPriority.CRITICAL.value:
                return 1
            elif priority == TaskPriority.HIGH.value:
                return 2
            elif priority == TaskPriority.MEDIUM.value:
                return 3
            else:
                return 4
        else:
            if priority == TaskPriority.CRITICAL.value:
                return 5
            elif priority == TaskPriority.HIGH.value:
                return 6
            elif priority == TaskPriority.MEDIUM.value:
                return 7
            else:
                return 8

    def get_daily_plan(
        self, db: Session, user_id: uuid.UUID, target_date_str: str | None = None
    ) -> DailyPlanRead:
        """Generate structured daily plan with summary, top 3 smart focus, and timeline buckets."""
        now_utc = datetime.now(UTC)

        if target_date_str:
            try:
                target_date = datetime.strptime(target_date_str, "%Y-%m-%d").date()
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date format. Expected YYYY-MM-DD.",
                )
        else:
            target_date = now_utc.date()

        start_of_day = datetime(target_date.year, target_date.month, target_date.day, 0, 0, 0, tzinfo=UTC)
        end_of_day = datetime(target_date.year, target_date.month, target_date.day, 23, 59, 59, 999999, tzinfo=UTC)

        # Query all active tasks for the user
        stmt = select(Task).where(
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
        )
        all_tasks = list(db.scalars(stmt).all())

        # Overdue tasks: deadline before start_of_day and not completed/cancelled
        overdue_tasks = [
            t for t in all_tasks
            if _to_utc(t.deadline) is not None
            and _to_utc(t.deadline) < start_of_day
            and t.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)
        ]

        # Tasks due on target_date
        due_tasks = [
            t for t in all_tasks
            if _to_utc(t.deadline) is not None
            and start_of_day <= _to_utc(t.deadline) <= end_of_day
        ]

        # Flexible / anytime tasks (if target_date is today or future, show unscheduled pending tasks)
        unscheduled_tasks = []
        if target_date == now_utc.date():
            unscheduled_tasks = [
                t for t in all_tasks
                if t.deadline is None
                and t.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)
            ]

        # Day tasks for summary metrics (due today)
        total_day_tasks = due_tasks
        completed_count = len([t for t in total_day_tasks if t.status == TaskStatus.COMPLETED.value])
        pending_count = len([t for t in total_day_tasks if t.status != TaskStatus.COMPLETED.value and t.status != TaskStatus.CANCELLED.value])
        total_count = len(total_day_tasks)
        completion_pct = (completed_count / total_count * 100.0) if total_count > 0 else 0.0

        total_est_minutes = sum(
            t.estimated_minutes or 0
            for t in total_day_tasks
            if t.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)
        )

        # Smart Focus Top 3: Actionable items (Overdue + Pending Day Tasks)
        actionable_pool = overdue_tasks + [
            t for t in due_tasks
            if t.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)
        ]
        if not actionable_pool and unscheduled_tasks:
            actionable_pool = unscheduled_tasks

        # Deduplicate & Sort by composite ranking score, nearest deadline, created_at desc
        unique_actionable = {t.id: t for t in actionable_pool}.values()
        sorted_focus = sorted(
            unique_actionable,
            key=lambda t: (
                self._get_composite_score(t, now_utc),
                _to_utc(t.deadline) if t.deadline else datetime.max.replace(tzinfo=UTC),
                -t.created_at.timestamp(),
            ),
        )
        focus_tasks = sorted_focus[:3]

        # Timeline Buckets: Morning (< 12:00), Afternoon (12:00 - 17:00), Evening (>= 17:00), Anytime
        morning_tasks: list[Task] = []
        afternoon_tasks: list[Task] = []
        evening_tasks: list[Task] = []

        for t in due_tasks:
            d_utc = _to_utc(t.deadline)
            if d_utc:
                hour = d_utc.hour
                if hour < 12:
                    morning_tasks.append(t)
                elif 12 <= hour < 17:
                    afternoon_tasks.append(t)
                else:
                    evening_tasks.append(t)

        timeline = [
            TimelineBucket(
                name="Morning",
                time_range="Before 12:00 PM",
                tasks=[TaskRead.model_validate(t) for t in morning_tasks],
            ),
            TimelineBucket(
                name="Afternoon",
                time_range="12:00 PM - 5:00 PM",
                tasks=[TaskRead.model_validate(t) for t in afternoon_tasks],
            ),
            TimelineBucket(
                name="Evening",
                time_range="After 5:00 PM",
                tasks=[TaskRead.model_validate(t) for t in evening_tasks],
            ),
            TimelineBucket(
                name="Anytime",
                time_range="Flexible",
                tasks=[TaskRead.model_validate(t) for t in unscheduled_tasks],
            ),
        ]

        summary = DayPlanSummary(
            total=total_count,
            completed=completed_count,
            pending=pending_count,
            overdue_count=len(overdue_tasks),
            completion_percentage=round(completion_pct, 1),
            total_estimated_minutes=total_est_minutes,
        )

        return DailyPlanRead(
            date=target_date.strftime("%Y-%m-%d"),
            summary=summary,
            overdue_tasks=[TaskRead.model_validate(t) for t in overdue_tasks],
            focus_tasks=[TaskRead.model_validate(t) for t in focus_tasks],
            timeline=timeline,
        )

    def get_weekly_plan(
        self, db: Session, user_id: uuid.UUID, start_date_str: str | None = None
    ) -> WeeklyPlanRead:
        """Generate 7-day overview with daily task, due, completed, and overdue metrics."""
        now_utc = datetime.now(UTC)

        if start_date_str:
            try:
                start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date()
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date format. Expected YYYY-MM-DD.",
                )
        else:
            # Default: start with current week's Monday
            today = now_utc.date()
            start_date = today - timedelta(days=today.weekday())

        end_date = start_date + timedelta(days=6)

        # Query all active tasks for user
        stmt = select(Task).where(
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
        )
        all_tasks = list(db.scalars(stmt).all())

        days: list[WeeklyPlanDay] = []
        total_weekly_tasks = 0
        total_weekly_completed = 0

        for i in range(7):
            current_day = start_date + timedelta(days=i)
            day_start = datetime(current_day.year, current_day.month, current_day.day, 0, 0, 0, tzinfo=UTC)
            day_end = datetime(current_day.year, current_day.month, current_day.day, 23, 59, 59, 999999, tzinfo=UTC)

            # Tasks due on this day
            due_on_day = [
                t for t in all_tasks
                if _to_utc(t.deadline) is not None and day_start <= _to_utc(t.deadline) <= day_end
            ]
            completed_on_day = [t for t in due_on_day if t.status == TaskStatus.COMPLETED.value]
            overdue_on_day = [
                t for t in all_tasks
                if _to_utc(t.deadline) is not None
                and _to_utc(t.deadline) < day_start
                and t.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)
            ]
            has_crit = any(t.priority == TaskPriority.CRITICAL.value for t in due_on_day)

            days.append(
                WeeklyPlanDay(
                    date=current_day.strftime("%Y-%m-%d"),
                    day_name=current_day.strftime("%A"),
                    task_count=len(due_on_day),
                    due_count=len(due_on_day),
                    completed_count=len(completed_on_day),
                    overdue_count=len(overdue_on_day),
                    has_critical=has_crit,
                )
            )
            total_weekly_tasks += len(due_on_day)
            total_weekly_completed += len(completed_on_day)

        return WeeklyPlanRead(
            start_date=start_date.strftime("%Y-%m-%d"),
            end_date=end_date.strftime("%Y-%m-%d"),
            days=days,
            total_tasks=total_weekly_tasks,
            completed_tasks=total_weekly_completed,
        )

    def move_task_to_today(self, db: Session, user_id: uuid.UUID, task_id: uuid.UUID) -> TaskRead:
        """Quick action to reschedule a task to today."""
        stmt = select(Task).where(
            Task.id == task_id,
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
        )
        task = db.scalars(stmt).first()
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found.",
            )

        now_utc = datetime.now(UTC)
        # Set deadline to today at 6:00 PM (18:00 UTC) or preserve hour
        hour = task.deadline.hour if task.deadline else 18
        minute = task.deadline.minute if task.deadline else 0
        task.deadline = datetime(now_utc.year, now_utc.month, now_utc.day, hour, minute, tzinfo=UTC)

        db.add(task)
        db.commit()
        db.refresh(task)
        return TaskRead.model_validate(task)

    def schedule_task(
        self, db: Session, user_id: uuid.UUID, task_id: uuid.UUID, new_deadline: datetime | None
    ) -> TaskRead:
        """Schedule or reschedule a task to a specific deadline."""
        stmt = select(Task).where(
            Task.id == task_id,
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
        )
        task = db.scalars(stmt).first()
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found.",
            )

        task.deadline = new_deadline
        db.add(task)
        db.commit()
        db.refresh(task)
        return TaskRead.model_validate(task)


planner_service = PlannerService()
