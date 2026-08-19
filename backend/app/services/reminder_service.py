import uuid
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.reminder import Reminder
from app.repositories.reminder_repository import reminder_repository
from app.repositories.task_repository import task_repository
from app.schemas.reminder import ReminderCreate, ReminderUpdate

MAX_REMINDERS_PER_TASK = 5


class ReminderService:
    """Service managing task reminder lifecycle and business validation."""

    def create_reminder(
        self, db: Session, reminder_in: ReminderCreate, user_id: uuid.UUID
    ) -> Reminder:
        """Create a new reminder with pre-deadline, future time, and per-task limit validation."""
        task = task_repository.get_by_id(db, reminder_in.task_id, user_id)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Associated task was not found.",
            )

        if task.status in ("COMPLETED", "CANCELLED"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot add reminder to a {task.status.lower()} task.",
            )

        # Enforce maximum active reminders limit per task (5)
        active_count = reminder_repository.count_active_by_task(db, reminder_in.task_id)
        if active_count >= MAX_REMINDERS_PER_TASK:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Maximum of {MAX_REMINDERS_PER_TASK} reminders allowed per task.",
            )

        now = datetime.now(UTC)
        remind_at = reminder_in.remind_at
        if remind_at.tzinfo is None:
            remind_at = remind_at.replace(tzinfo=UTC)

        # Validate future time
        if remind_at < now - timedelta(minutes=1):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Reminder time must be in the future.",
            )

        # Enforce Pre-Deadline Constraint: cannot set reminder after task deadline
        if task.deadline is not None:
            task_deadline = task.deadline
            if task_deadline.tzinfo is None:
                task_deadline = task_deadline.replace(tzinfo=UTC)
            if remind_at > task_deadline:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Reminder time cannot be scheduled after the task deadline.",
                )

        return reminder_repository.create(db, reminder_in)

    def get_reminder_by_id(
        self, db: Session, reminder_id: uuid.UUID, user_id: uuid.UUID
    ) -> Reminder:
        """Fetch single reminder or raise 404."""
        reminder = reminder_repository.get_by_id(db, reminder_id, user_id)
        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found.",
            )
        return reminder

    def get_user_reminders(
        self,
        db: Session,
        user_id: uuid.UUID,
        task_id: uuid.UUID | None = None,
        status_filter: str | None = None,
        limit: int = 100,
    ) -> list[Reminder]:
        """Fetch all reminders for user."""
        return reminder_repository.get_user_reminders(
            db=db,
            user_id=user_id,
            task_id=task_id,
            status=status_filter,
            limit=limit,
        )

    def update_reminder(
        self,
        db: Session,
        reminder_id: uuid.UUID,
        reminder_in: ReminderUpdate,
        user_id: uuid.UUID,
    ) -> Reminder:
        """Update reminder timestamp or status with validation."""
        reminder = self.get_reminder_by_id(db, reminder_id, user_id)

        if reminder_in.remind_at is not None:
            now = datetime.now(UTC)
            remind_at = reminder_in.remind_at
            if remind_at.tzinfo is None:
                remind_at = remind_at.replace(tzinfo=UTC)

            if remind_at < now - timedelta(minutes=1):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Reminder time must be in the future.",
                )

            if reminder.task.deadline is not None:
                task_deadline = reminder.task.deadline
                if task_deadline.tzinfo is None:
                    task_deadline = task_deadline.replace(tzinfo=UTC)
                if remind_at > task_deadline:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Reminder time cannot be scheduled after the task deadline.",
                    )

        return reminder_repository.update(db, reminder, reminder_in)

    def delete_reminder(
        self, db: Session, reminder_id: uuid.UUID, user_id: uuid.UUID
    ) -> None:
        """Soft delete / cancel a reminder."""
        reminder = self.get_reminder_by_id(db, reminder_id, user_id)
        reminder_repository.delete(db, reminder)


reminder_service = ReminderService()
