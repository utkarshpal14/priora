import uuid
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.task import Task
from app.repositories.category_repository import category_repository
from app.repositories.task_repository import task_repository
from app.schemas.task import TaskCreate, TaskListResponse, TaskRead, TaskUpdate


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
        """Create new task with past deadline validation and category verification."""
        # Due Date Validation: Prevent past deadlines on task creation
        if task_in.deadline is not None:
            now = datetime.now(UTC)
            # Ensure deadline is timezone-aware
            deadline = task_in.deadline
            if deadline.tzinfo is None:
                deadline = deadline.replace(tzinfo=UTC)
            if deadline < now - timedelta(minutes=5):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Task deadline cannot be set in the past.",
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
        """Update task properties."""
        task = self.get_task_by_id(db, task_id, user_id)

        # Validate category ownership if updating category
        if task_in.category_id is not None:
            category = category_repository.get_by_id(db, task_in.category_id, user_id)
            if not category:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Specified category was not found.",
                )

        return task_repository.update(db, task, task_in)

    def complete_task(
        self, db: Session, task_id: uuid.UUID, user_id: uuid.UUID
    ) -> Task:
        """Complete task lifecycle transition."""
        task = self.get_task_by_id(db, task_id, user_id)
        return task_repository.complete(db, task)

    def reopen_task(
        self, db: Session, task_id: uuid.UUID, user_id: uuid.UUID
    ) -> Task:
        """Reopen task lifecycle transition."""
        task = self.get_task_by_id(db, task_id, user_id)
        return task_repository.reopen(db, task)

    def delete_task(
        self, db: Session, task_id: uuid.UUID, user_id: uuid.UUID
    ) -> None:
        """Soft delete task."""
        task = self.get_task_by_id(db, task_id, user_id)
        task_repository.delete(db, task)


task_service = TaskService()
