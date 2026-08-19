import uuid
from datetime import UTC, date, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.task import Task
from app.models.task_session import TaskSession
from app.repositories.task_session_repository import task_session_repository
from app.schemas.planner import (
    DailyPlanRead,
    DayPlanSummary,
    TimelineBucket,
    WeeklyPlanDay,
    WeeklyPlanRead,
)
from app.schemas.task import TaskPriority, TaskRead, TaskStatus
from app.schemas.task_session import (
    TaskSessionCreate,
    TaskSessionRead,
    TaskSessionUpdate,
)


def _to_utc(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt.astimezone(UTC)


class PlannerService:
    """Service coordinating daily and weekly timeline planning and hourly work session scheduling."""

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

    def _format_time_range(self, start_dt: datetime, end_dt: datetime) -> str:
        s_str = start_dt.strftime("%I:%M %p").lstrip("0")
        e_str = end_dt.strftime("%I:%M %p").lstrip("0")
        return f"{s_str} – {e_str}"

    def _detect_conflicts_for_blocks(self, blocks: list[TaskSessionRead]) -> dict[uuid.UUID, list[str]]:
        conflicts: dict[uuid.UUID, list[str]] = {b.id: [] for b in blocks}
        for i in range(len(blocks)):
            for j in range(i + 1, len(blocks)):
                b1, b2 = blocks[i], blocks[j]
                start1 = _to_utc(b1.scheduled_start)
                end1 = _to_utc(b1.scheduled_end)
                start2 = _to_utc(b2.scheduled_start)
                end2 = _to_utc(b2.scheduled_end)
                if start1 and end1 and start2 and end2:
                    if start1 < end2 and start2 < end1:
                        t1_title = b1.task.title if b1.task else "Task"
                        t2_title = b2.task.title if b2.task else "Task"
                        conflicts[b1.id].append(t2_title)
                        conflicts[b2.id].append(t1_title)
        return conflicts

    def _detect_conflicts(self, sessions: list[TaskSession]) -> dict[uuid.UUID, list[str]]:
        conflicts: dict[uuid.UUID, list[str]] = {s.id: [] for s in sessions}
        for i in range(len(sessions)):
            for j in range(i + 1, len(sessions)):
                s1, s2 = sessions[i], sessions[j]
                start1 = _to_utc(s1.scheduled_start)
                end1 = _to_utc(s1.scheduled_end)
                start2 = _to_utc(s2.scheduled_start)
                end2 = _to_utc(s2.scheduled_end)
                if start1 and end1 and start2 and end2:
                    if start1 < end2 and start2 < end1:
                        t1_title = s1.task.title if s1.task else "Task"
                        t2_title = s2.task.title if s2.task else "Task"
                        conflicts[s1.id].append(t2_title)
                        conflicts[s2.id].append(t1_title)
        return conflicts

    def get_daily_plan(
        self, db: Session, user_id: uuid.UUID, target_date_str: str | None = None, tz_offset_minutes: int = 0
    ) -> DailyPlanRead:
        """Generate structured daily plan with hourly time-blocks, unscheduled tasks, and summary."""
        offset_delta = timedelta(minutes=tz_offset_minutes)
        now_utc = datetime.now(UTC)
        now_local = now_utc + offset_delta

        if target_date_str:
            try:
                target_date = datetime.strptime(target_date_str, "%Y-%m-%d").date()
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date format. Expected YYYY-MM-DD.",
                )
        else:
            target_date = now_local.date()

        # Local start/end of day converted to UTC
        local_start = datetime(target_date.year, target_date.month, target_date.day, 0, 0, 0)
        start_of_day = (local_start - offset_delta).replace(tzinfo=UTC)

        local_end = datetime(target_date.year, target_date.month, target_date.day, 23, 59, 59, 999999)
        end_of_day = (local_end - offset_delta).replace(tzinfo=UTC)

        # Query all active tasks for the user
        stmt = select(Task).where(
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
        )
        all_tasks = list(db.scalars(stmt).all())

        # Overdue tasks: deadline strictly before today's start_of_day and not completed/cancelled
        overdue_tasks = [
            t for t in all_tasks
            if _to_utc(t.deadline) is not None
            and _to_utc(t.deadline) < start_of_day
            and t.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)
        ]

        # Tasks due on target_date (within local day boundaries)
        due_tasks = [
            t for t in all_tasks
            if _to_utc(t.deadline) is not None
            and start_of_day <= _to_utc(t.deadline) <= end_of_day
        ]

        # Query TaskSessions for target_date
        raw_sessions = task_session_repository.get_for_user_on_date(
            db, user_id, start_of_day, end_of_day
        )

        time_blocks: list[TaskSessionRead] = []
        scheduled_task_ids: set[uuid.UUID] = set()

        for s in raw_sessions:
            start_utc = _to_utc(s.scheduled_start) or s.scheduled_start
            end_utc = _to_utc(s.scheduled_end) or s.scheduled_end
            dur_mins = max(1, int((end_utc - start_utc).total_seconds() / 60))
            range_str = self._format_time_range(start_utc, end_utc)
            task_read = TaskRead.model_validate(s.task) if s.task else None
            scheduled_task_ids.add(s.task_id)

            time_blocks.append(
                TaskSessionRead(
                    id=s.id,
                    task_id=s.task_id,
                    scheduled_start=s.scheduled_start,
                    scheduled_end=s.scheduled_end,
                    duration_minutes=dur_mins,
                    formatted_time_range=range_str,
                    has_conflict=False,
                    conflicting_with=[],
                    task=task_read,
                    created_at=s.created_at,
                    updated_at=s.updated_at,
                )
            )

        # Auto-placement for tasks scheduled for target_date
        for t in due_tasks:
            if t.status in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value):
                continue
            if t.id in scheduled_task_ids:
                continue

            deadline_utc = _to_utc(t.deadline)
            if deadline_utc is not None:
                dur_mins = t.estimated_minutes if (t.estimated_minutes and t.estimated_minutes > 0) else 60
                session_start = max(start_of_day, deadline_utc - timedelta(minutes=dur_mins))
                session_end = max(session_start + timedelta(minutes=15), deadline_utc)
                range_str = self._format_time_range(session_start, session_end)
                auto_id = uuid.uuid5(uuid.NAMESPACE_DNS, f"auto_{t.id}_{target_date}")
                task_read = TaskRead.model_validate(t)
                scheduled_task_ids.add(t.id)

                time_blocks.append(
                    TaskSessionRead(
                        id=auto_id,
                        task_id=t.id,
                        scheduled_start=session_start,
                        scheduled_end=session_end,
                        duration_minutes=dur_mins,
                        formatted_time_range=range_str,
                        has_conflict=False,
                        conflicting_with=[],
                        task=task_read,
                        created_at=t.created_at,
                        updated_at=t.updated_at,
                    )
                )

        # Sort time blocks chronologically
        time_blocks.sort(key=lambda b: _to_utc(b.scheduled_start) or datetime.min.replace(tzinfo=UTC))

        # Detect conflicts across all time blocks
        conflict_map = self._detect_conflicts_for_blocks(time_blocks)
        for b in time_blocks:
            confs = conflict_map.get(b.id, [])
            b.has_conflict = len(confs) > 0
            b.conflicting_with = confs

        # Unscheduled tasks pool: active tasks due today or pending without sessions today
        # Note: Incomplete tasks whose deadline was earlier today (or in past days) will NOT be in scheduled_task_ids,
        # so they will cleanly appear here in unscheduled_tasks ("Ready to Schedule") and in focus_tasks!
        unscheduled_tasks: list[Task] = [
            t for t in (due_tasks + overdue_tasks)
            if t.id not in scheduled_task_ids
            and t.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)
        ]
        # Deduplicate
        unique_unscheduled = {t.id: t for t in unscheduled_tasks}.values()

        # Build composite pool for smart focus
        focus_pool = list({t.id: t for t in (overdue_tasks + due_tasks)}.values())
        sorted_focus = sorted(
            [t for t in focus_pool if t.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)],
            key=lambda t: (
                self._get_composite_score(t, now_utc),
                _to_utc(t.deadline) if t.deadline else datetime.max.replace(tzinfo=UTC),
                -t.created_at.timestamp(),
            ),
        )
        focus_tasks = sorted_focus[:3]

        # Calculate metrics
        completed_today = sum(1 for t in due_tasks if t.status == TaskStatus.COMPLETED.value)
        total_for_day = len(due_tasks)
        pending_for_day = max(0, total_for_day - completed_today)
        completion_pct = (
            round((completed_today / total_for_day * 100.0), 1) if total_for_day > 0 else 0.0
        )
        total_est_minutes = sum(s.duration_minutes for s in time_blocks) or sum(t.estimated_minutes or 0 for t in due_tasks)

        # Legacy timeline buckets for backward compatibility
        morning_tasks: list[Task] = []
        afternoon_tasks: list[Task] = []
        evening_tasks: list[Task] = []
        anytime_tasks: list[Task] = []

        for t in due_tasks:
            dt = _to_utc(t.deadline)
            if dt is None:
                anytime_tasks.append(t)
            elif dt.hour < 12:
                morning_tasks.append(t)
            elif 12 <= dt.hour < 17:
                afternoon_tasks.append(t)
            else:
                evening_tasks.append(t)

        legacy_timeline = [
            TimelineBucket(name="Morning", time_range="Before 12:00 PM", tasks=[TaskRead.model_validate(t) for t in morning_tasks]),
            TimelineBucket(name="Afternoon", time_range="12:00 PM - 5:00 PM", tasks=[TaskRead.model_validate(t) for t in afternoon_tasks]),
            TimelineBucket(name="Evening", time_range="After 5:00 PM", tasks=[TaskRead.model_validate(t) for t in evening_tasks]),
            TimelineBucket(name="Anytime", time_range="Flexible", tasks=[TaskRead.model_validate(t) for t in anytime_tasks]),
        ]

        summary = DayPlanSummary(
            total=total_for_day,
            completed=completed_today,
            pending=pending_for_day,
            overdue_count=len(overdue_tasks),
            completion_percentage=completion_pct,
            total_estimated_minutes=total_est_minutes,
        )

        return DailyPlanRead(
            date=target_date.strftime("%Y-%m-%d"),
            summary=summary,
            overdue_tasks=[TaskRead.model_validate(t) for t in overdue_tasks],
            focus_tasks=[TaskRead.model_validate(t) for t in focus_tasks],
            time_blocks=time_blocks,
            unscheduled_tasks=[TaskRead.model_validate(t) for t in unique_unscheduled],
            timeline=legacy_timeline,
        )

    def get_weekly_plan(
        self, db: Session, user_id: uuid.UUID, start_date_str: str | None = None, tz_offset_minutes: int = 0
    ) -> WeeklyPlanRead:
        """Generate 7-day schedule overview with task counts, due counts, and completion statuses."""
        offset_delta = timedelta(minutes=tz_offset_minutes)
        now_utc = datetime.now(UTC)
        now_local = now_utc + offset_delta

        if start_date_str:
            try:
                start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date()
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date format. Expected YYYY-MM-DD.",
                )
        else:
            # Default to current week's Monday in user's local time
            current_day = now_local.date()
            start_date = current_day - timedelta(days=current_day.weekday())

        end_date = start_date + timedelta(days=6)
        local_start = datetime(start_date.year, start_date.month, start_date.day, 0, 0, 0)
        start_dt = (local_start - offset_delta).replace(tzinfo=UTC)

        local_end = datetime(end_date.year, end_date.month, end_date.day, 23, 59, 59, 999999)
        end_dt = (local_end - offset_delta).replace(tzinfo=UTC)

        stmt = select(Task).where(
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
            Task.deadline >= start_dt,
            Task.deadline <= end_dt,
        )
        tasks = list(db.scalars(stmt).all())

        days: list[WeeklyPlanDay] = []
        total_weekly_tasks = 0
        total_weekly_completed = 0

        for i in range(7):
            current_day = start_date + timedelta(days=i)
            day_local_start = datetime(current_day.year, current_day.month, current_day.day, 0, 0, 0)
            day_start = (day_local_start - offset_delta).replace(tzinfo=UTC)

            day_local_end = datetime(current_day.year, current_day.month, current_day.day, 23, 59, 59, 999999)
            day_end = (day_local_end - offset_delta).replace(tzinfo=UTC)

            due_on_day = [
                t for t in tasks
                if _to_utc(t.deadline) is not None
                and day_start <= _to_utc(t.deadline) <= day_end
            ]
            completed_on_day = [t for t in due_on_day if t.status == TaskStatus.COMPLETED.value]
            overdue_on_day = [
                t for t in due_on_day
                if _to_utc(t.deadline) is not None
                and _to_utc(t.deadline) < now_utc
                and t.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)
            ]
            has_crit = any(t.priority.upper() == TaskPriority.CRITICAL.value for t in due_on_day)

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

    # ----------------- Task Session Operations -----------------

    def create_session(
        self, db: Session, user_id: uuid.UUID, session_in: TaskSessionCreate
    ) -> TaskSessionRead:
        """Create a scheduled hourly focus block for a task."""
        # Verify task exists and belongs to user
        stmt = select(Task).where(
            Task.id == session_in.task_id,
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
        )
        task = db.scalar(stmt)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found.",
            )

        if session_in.scheduled_end <= session_in.scheduled_start:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="scheduled_end must be strictly after scheduled_start.",
            )

        session = task_session_repository.create(
            db, session_in.task_id, session_in.scheduled_start, session_in.scheduled_end
        )

        start_utc = _to_utc(session.scheduled_start) or session.scheduled_start
        end_utc = _to_utc(session.scheduled_end) or session.scheduled_end
        dur_mins = max(1, int((end_utc - start_utc).total_seconds() / 60))
        range_str = self._format_time_range(start_utc, end_utc)

        return TaskSessionRead(
            id=session.id,
            task_id=session.task_id,
            scheduled_start=session.scheduled_start,
            scheduled_end=session.scheduled_end,
            duration_minutes=dur_mins,
            formatted_time_range=range_str,
            task=TaskRead.model_validate(task),
            created_at=session.created_at,
            updated_at=session.updated_at,
        )

    def update_session(
        self,
        db: Session,
        user_id: uuid.UUID,
        session_id: uuid.UUID,
        session_in: TaskSessionUpdate,
    ) -> TaskSessionRead:
        """Update a scheduled focus block time window."""
        session = task_session_repository.get_by_id(db, session_id, user_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found.",
            )

        new_start = _to_utc(session_in.scheduled_start or session.scheduled_start)
        new_end = _to_utc(session_in.scheduled_end or session.scheduled_end)

        if new_start is not None and new_end is not None and new_end <= new_start:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="scheduled_end must be strictly after scheduled_start.",
            )

        updated = task_session_repository.update(db, session, session_in.scheduled_start, session_in.scheduled_end)
        start_utc = _to_utc(updated.scheduled_start) or updated.scheduled_start
        end_utc = _to_utc(updated.scheduled_end) or updated.scheduled_end
        dur_mins = max(1, int((end_utc - start_utc).total_seconds() / 60))
        range_str = self._format_time_range(start_utc, end_utc)

        return TaskSessionRead(
            id=updated.id,
            task_id=updated.task_id,
            scheduled_start=updated.scheduled_start,
            scheduled_end=updated.scheduled_end,
            duration_minutes=dur_mins,
            formatted_time_range=range_str,
            task=TaskRead.model_validate(updated.task) if updated.task else None,
            created_at=updated.created_at,
            updated_at=updated.updated_at,
        )

    def delete_session(self, db: Session, user_id: uuid.UUID, session_id: uuid.UUID) -> None:
        """Delete a scheduled focus block."""
        session = task_session_repository.get_by_id(db, session_id, user_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found.",
            )
        task_session_repository.delete(db, session)

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
