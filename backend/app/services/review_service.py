import uuid
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.task import Task
from app.schemas.review import (
    BatchRescheduleResponse,
    RescheduleAction,
    RescheduleItem,
    ReviewSummaryRead,
)
from app.schemas.task import TaskPriority, TaskRead, TaskStatus


def _to_utc(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt.astimezone(UTC)


class ReviewService:
    """Service providing end-of-day review summaries and batch rescheduling."""

    def _get_urgency_rank(self, task: Task, now_utc: datetime) -> int:
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

    def get_daily_review(
        self, db: Session, user_id: uuid.UUID, target_date_str: str | None = None
    ) -> ReviewSummaryRead:
        """Fetch completed accomplishments and unfinished rollover tasks for daily review."""
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

        # Query all active tasks for user
        stmt = select(Task).where(
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
        )
        all_tasks = list(db.scalars(stmt).all())

        # Completed on target date
        completed_today = [
            t for t in all_tasks
            if t.status == TaskStatus.COMPLETED.value
            and t.completed_at is not None
            and start_of_day <= _to_utc(t.completed_at) <= end_of_day
        ]

        # Overdue tasks (deadline before start_of_day and not completed/cancelled)
        overdue_tasks = [
            t for t in all_tasks
            if _to_utc(t.deadline) is not None
            and _to_utc(t.deadline) < start_of_day
            and t.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)
        ]

        # Tasks due on target date that remain incomplete
        due_today_incomplete = [
            t for t in all_tasks
            if _to_utc(t.deadline) is not None
            and start_of_day <= _to_utc(t.deadline) <= end_of_day
            and t.status not in (TaskStatus.COMPLETED.value, TaskStatus.CANCELLED.value)
        ]

        # Incomplete pool (Overdue + Due today pending)
        incomplete_pool = {t.id: t for t in (overdue_tasks + due_today_incomplete)}.values()
        sorted_incomplete = sorted(
            incomplete_pool,
            key=lambda t: (
                self._get_urgency_rank(t, now_utc),
                _to_utc(t.deadline) if t.deadline else datetime.max.replace(tzinfo=UTC),
                -t.created_at.timestamp(),
            ),
        )

        completed_count = len(completed_today)
        incomplete_count = len(sorted_incomplete)
        overdue_count = len(overdue_tasks)
        total_active_day = completed_count + incomplete_count
        completion_rate = (
            round((completed_count / total_active_day * 100.0), 1)
            if total_active_day > 0
            else 0.0
        )
        total_completed_minutes = sum(t.estimated_minutes or 0 for t in completed_today)

        return ReviewSummaryRead(
            date=target_date.strftime("%Y-%m-%d"),
            completed_tasks=[TaskRead.model_validate(t) for t in completed_today],
            incomplete_tasks=[TaskRead.model_validate(t) for t in sorted_incomplete],
            completed_count=completed_count,
            incomplete_count=incomplete_count,
            overdue_count=overdue_count,
            completion_rate=completion_rate,
            total_completed_minutes=total_completed_minutes,
        )

    def batch_reschedule(
        self, db: Session, user_id: uuid.UUID, items: list[RescheduleItem]
    ) -> BatchRescheduleResponse:
        """Batch process and reschedule incomplete tasks."""
        if not items:
            return BatchRescheduleResponse(processed_count=0, updated_tasks=[])

        task_ids = [item.task_id for item in items]
        stmt = select(Task).where(
            Task.id.in_(task_ids),
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
        )
        tasks = list(db.scalars(stmt).all())
        task_map = {t.id: t for t in tasks}

        now_utc = datetime.now(UTC)
        updated_tasks: list[Task] = []

        for item in items:
            task = task_map.get(item.task_id)
            if not task:
                continue

            if item.action == RescheduleAction.MOVE_TOMORROW:
                tomorrow = now_utc.date() + timedelta(days=1)
                hour = task.deadline.hour if task.deadline else 18
                minute = task.deadline.minute if task.deadline else 0
                task.deadline = datetime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute, tzinfo=UTC)

            elif item.action == RescheduleAction.MOVE_NEXT_WEEK:
                next_week = now_utc.date() + timedelta(days=7)
                hour = task.deadline.hour if task.deadline else 18
                minute = task.deadline.minute if task.deadline else 0
                task.deadline = datetime(next_week.year, next_week.month, next_week.day, hour, minute, tzinfo=UTC)

            elif item.action == RescheduleAction.SCHEDULE:
                if not item.new_deadline:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"new_deadline is required for SCHEDULE action on task '{task.title}'.",
                    )
                task.deadline = item.new_deadline

            elif item.action == RescheduleAction.COMPLETE:
                task.status = TaskStatus.COMPLETED.value
                task.completed_at = now_utc

            elif item.action == RescheduleAction.CANCEL:
                task.status = TaskStatus.CANCELLED.value

            task.updated_at = now_utc
            db.add(task)
            updated_tasks.append(task)

        db.commit()
        for t in updated_tasks:
            db.refresh(t)

        return BatchRescheduleResponse(
            processed_count=len(updated_tasks),
            updated_tasks=[TaskRead.model_validate(t) for t in updated_tasks],
        )


review_service = ReviewService()
