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

        updated_task = task_repository.update(db, task, task_in)

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
        # Auto-Cancel Rule: clear all scheduled reminders for finished tasks
        reminder_repository.cancel_task_reminders(db, task_id, user_id)
        return completed_task

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

