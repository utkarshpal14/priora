import uuid
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.task import Task
from app.repositories.category_repository import category_repository
from app.repositories.reminder_repository import reminder_repository
from app.repositories.task_repository import task_repository
from app.schemas.task import TaskCreate, TaskListResponse, TaskRead, TaskStatus, TaskUpdate


class TaskService:
    """Service coordinating task business logic and lifecycle rules."""

    def get_tasks(
        self,
        db: Session,
        user_id: uuid.UUID,
        status_filter: str | None = None,
        priority_filter: str | None = None,
        category_id: uuid.UUID | None = None,
        search: str | None = None,
        limit: int = 100,
    ) -> TaskListResponse:
        """Fetch tasks list and user metrics summary."""
        tasks = task_repository.get_tasks(
            db=db,
            user_id=user_id,
            status=status_filter,
            priority=priority_filter,
            category_id=category_id,
            search=search,
            limit=limit,
        )
        metrics = task_repository.get_metrics(db=db, user_id=user_id)
        return TaskListResponse(
            tasks=[TaskRead.model_validate(t) for t in tasks],
            metrics=metrics,
        )

    def get_task_by_id(
        self, db: Session, task_id: uuid.UUID, user_id: uuid.UUID
    ) -> Task:
        """Fetch task or raise 404 with user isolation."""
        task = task_repository.get_by_id(db, task_id, user_id)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found.",
            )
        return task

    def create_task(
        self, db: Session, task_in: TaskCreate, user_id: uuid.UUID
    ) -> Task:
        """Create new task with category verification."""

        # Time Window Validation
        if task_in.scheduled_start and task_in.scheduled_end:
            start_utc = task_in.scheduled_start if task_in.scheduled_start.tzinfo else task_in.scheduled_start.replace(tzinfo=UTC)
            end_utc = task_in.scheduled_end if task_in.scheduled_end.tzinfo else task_in.scheduled_end.replace(tzinfo=UTC)
            if end_utc <= start_utc:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="scheduled_end must be strictly after scheduled_start.",
                )

        # Validate category ownership if provided
        if task_in.category_id is not None:
            category = category_repository.get_by_id(db, task_in.category_id, user_id)
            if not category:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Specified category was not found.",
                )

        return task_repository.create(db, task_in, user_id)

    def update_task(
        self,
        db: Session,
        task_id: uuid.UUID,
        task_in: TaskUpdate,
        user_id: uuid.UUID,
    ) -> Task:
        """Update task properties and auto-cancel reminders if status is CANCELLED."""
        task = self.get_task_by_id(db, task_id, user_id)

        # Validate category ownership if updating category
        if task_in.category_id is not None:
            category = category_repository.get_by_id(db, task_in.category_id, user_id)
            if not category:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Specified category was not found.",
                )

        # Time Window Validation
        new_start = task_in.scheduled_start or task.scheduled_start
        new_end = task_in.scheduled_end or task.scheduled_end
        if new_start and new_end:
            start_utc = new_start if new_start.tzinfo else new_start.replace(tzinfo=UTC)
            end_utc = new_end if new_end.tzinfo else new_end.replace(tzinfo=UTC)
            if end_utc <= start_utc:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="scheduled_end must be strictly after scheduled_start.",
                )

        old_status = task.status
        updated_task = task_repository.update(db, task, task_in)

        # Recurring Task Engine: generate next occurrence if task marked completed
        if task_in.status == TaskStatus.COMPLETED and old_status != "COMPLETED":
            self._handle_recurrence_on_completion(db, updated_task)

        # Auto-cancel scheduled reminders if status transitioned to CANCELLED or COMPLETED
        if task_in.status in (TaskStatus.CANCELLED, TaskStatus.COMPLETED):
            reminder_repository.cancel_task_reminders(db, task_id, user_id)

        return updated_task

    def complete_task(
        self, db: Session, task_id: uuid.UUID, user_id: uuid.UUID
    ) -> Task:
        """Complete task lifecycle transition and auto-cancel scheduled reminders."""
        task = self.get_task_by_id(db, task_id, user_id)
        completed_task = task_repository.complete(db, task)
        # Recurring Task Engine: generate next occurrence if repeat_type != none
        self._handle_recurrence_on_completion(db, task)
        # Auto-Cancel Rule: clear all scheduled reminders for finished tasks
        reminder_repository.cancel_task_reminders(db, task_id, user_id)
        return completed_task

    def _handle_recurrence_on_completion(self, db: Session, task: Task) -> Task | None:
        """
        Recurring Task Engine (TS-003, TS-004):
        When a recurring task is completed, automatically instantiate the next occurrence
        and copy any active reminders with the appropriate time offset.
        """
        repeat_type = (task.repeat_type or "none").lower()
        if repeat_type == "none":
            return None

        interval = task.repeat_interval or 1
        now = datetime.now(UTC)

        # 1. Compute Next Deadline
        next_deadline: datetime | None = None
        if task.deadline:
            base_deadline_utc = task.deadline if task.deadline.tzinfo else task.deadline.replace(tzinfo=UTC)
            if repeat_type == "daily":
                next_deadline = base_deadline_utc + timedelta(days=1 * interval)
            elif repeat_type == "weekly":
                next_deadline = base_deadline_utc + timedelta(weeks=1 * interval)
            elif repeat_type == "monthly":
                month = base_deadline_utc.month + interval
                year = base_deadline_utc.year + (month - 1) // 12
                month = ((month - 1) % 12) + 1
                day = min(base_deadline_utc.day, 28)
                next_deadline = base_deadline_utc.replace(year=year, month=month, day=day)
            else:
                return None

            # Check repeat_end_date
            if task.repeat_end_date:
                end_date_utc = task.repeat_end_date if task.repeat_end_date.tzinfo else task.repeat_end_date.replace(tzinfo=UTC)
                if next_deadline > end_date_utc:
                    return None
        else:
            if task.repeat_end_date:
                end_date_utc = task.repeat_end_date if task.repeat_end_date.tzinfo else task.repeat_end_date.replace(tzinfo=UTC)
                projected_time = now + (timedelta(days=1 * interval) if repeat_type == "daily" else timedelta(weeks=1 * interval))
                if projected_time > end_date_utc:
                    return None

        # 2. Compute Next Scheduled Start/End
        next_start: datetime | None = None
        next_end: datetime | None = None
        if task.scheduled_start:
            start_utc = task.scheduled_start if task.scheduled_start.tzinfo else task.scheduled_start.replace(tzinfo=UTC)
            if repeat_type == "daily":
                next_start = start_utc + timedelta(days=1 * interval)
            elif repeat_type == "weekly":
                next_start = start_utc + timedelta(weeks=1 * interval)
            elif repeat_type == "monthly":
                month = start_utc.month + interval
                year = start_utc.year + (month - 1) // 12
                month = ((month - 1) % 12) + 1
                day = min(start_utc.day, 28)
                next_start = start_utc.replace(year=year, month=month, day=day)

        if task.scheduled_end:
            end_utc = task.scheduled_end if task.scheduled_end.tzinfo else task.scheduled_end.replace(tzinfo=UTC)
            if repeat_type == "daily":
                next_end = end_utc + timedelta(days=1 * interval)
            elif repeat_type == "weekly":
                next_end = end_utc + timedelta(weeks=1 * interval)
            elif repeat_type == "monthly":
                month = end_utc.month + interval
                year = end_utc.year + (month - 1) // 12
                month = ((month - 1) % 12) + 1
                day = min(end_utc.day, 28)
                next_end = end_utc.replace(year=year, month=month, day=day)

        # 3. Create Next Task Occurrence
        next_task = Task(
            user_id=task.user_id,
            category_id=task.category_id,
            goal_id=task.goal_id,
            milestone_id=task.milestone_id,
            title=task.title,
            description=task.description,
            priority=task.priority,
            status="PENDING",
            deadline=next_deadline,
            scheduled_start=next_start,
            scheduled_end=next_end,
            estimated_minutes=task.estimated_minutes,
            repeat_type=task.repeat_type,
            repeat_interval=task.repeat_interval,
            repeat_end_date=task.repeat_end_date,
        )
        db.add(next_task)
        db.commit()
        db.refresh(next_task)

        # 4. Auto-create session if both start and end times provided
        if next_start and next_end:
            from app.models.task_session import TaskSession
            session = TaskSession(
                task_id=next_task.id,
                scheduled_start=next_start,
                scheduled_end=next_end,
            )
            db.add(session)
            db.commit()

        # 5. Clone Reminders (TS-004 Recurring Reminders)
        # Inherit reminders where not is_deleted, regardless of transient delivery state (SENT, DELIVERED, CANCELLED)
        if task.reminders:
            from app.models.reminder import Reminder
            for orig_r in task.reminders:
                if not orig_r.is_deleted:
                    next_remind_at: datetime | None = None
                    if task.deadline and orig_r.remind_at and next_deadline:
                        orig_dl_utc = task.deadline if task.deadline.tzinfo else task.deadline.replace(tzinfo=UTC)
                        orig_r_utc = orig_r.remind_at if orig_r.remind_at.tzinfo else orig_r.remind_at.replace(tzinfo=UTC)
                        offset = orig_dl_utc - orig_r_utc
                        next_remind_at = next_deadline - offset
                    elif task.scheduled_start and orig_r.remind_at and next_start:
                        orig_st_utc = task.scheduled_start if task.scheduled_start.tzinfo else task.scheduled_start.replace(tzinfo=UTC)
                        orig_r_utc = orig_r.remind_at if orig_r.remind_at.tzinfo else orig_r.remind_at.replace(tzinfo=UTC)
                        offset = orig_st_utc - orig_r_utc
                        next_remind_at = next_start - offset
                    elif orig_r.remind_at:
                        orig_r_utc = orig_r.remind_at if orig_r.remind_at.tzinfo else orig_r.remind_at.replace(tzinfo=UTC)
                        if repeat_type == "daily":
                            next_remind_at = orig_r_utc + timedelta(days=1 * interval)
                        elif repeat_type == "weekly":
                            next_remind_at = orig_r_utc + timedelta(weeks=1 * interval)
                        elif repeat_type == "monthly":
                            month = orig_r_utc.month + interval
                            year = orig_r_utc.year + (month - 1) // 12
                            month = ((month - 1) % 12) + 1
                            day = min(orig_r_utc.day, 28)
                            next_remind_at = orig_r_utc.replace(year=year, month=month, day=day)

                    if next_remind_at and next_remind_at > now:
                        new_r = Reminder(
                            task_id=next_task.id,
                            remind_at=next_remind_at,
                            status="SCHEDULED",
                        )
                        db.add(new_r)
            db.commit()
            db.refresh(next_task)

        return next_task

    def reopen_task(
        self, db: Session, task_id: uuid.UUID, user_id: uuid.UUID
    ) -> Task:
        """Reopen task lifecycle transition."""
        task = self.get_task_by_id(db, task_id, user_id)
        return task_repository.reopen(db, task)

    def delete_task(
        self, db: Session, task_id: uuid.UUID, user_id: uuid.UUID
    ) -> None:
        """Soft delete task and cancel all associated reminders."""
        task = self.get_task_by_id(db, task_id, user_id)
        task_repository.delete(db, task)
        # Auto-Cancel Rule: clear all scheduled reminders for soft-deleted tasks
        reminder_repository.cancel_task_reminders(db, task_id, user_id)


task_service = TaskService()

