import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.reminder import Reminder
from app.models.task import Task
from app.schemas.reminder import ReminderCreate, ReminderUpdate


class ReminderRepository:
    """Repository handling database operations for the Reminder entity."""

    def create(self, db: Session, reminder_in: ReminderCreate) -> Reminder:
        """Create a new reminder associated with a task."""
        now = datetime.now(UTC)
        remind_at = reminder_in.remind_at
        if remind_at.tzinfo is None:
            remind_at = remind_at.replace(tzinfo=UTC)

        db_reminder = Reminder(
            task_id=reminder_in.task_id,
            notification_id=reminder_in.notification_id,
            remind_at=remind_at,
            status="SCHEDULED",
            created_at=now,
            updated_at=now,
            is_deleted=False,
        )
        db.add(db_reminder)
        db.commit()
        db.refresh(db_reminder)
        return db_reminder

    def get_by_id(
        self, db: Session, reminder_id: uuid.UUID, user_id: uuid.UUID
    ) -> Reminder | None:
        """Fetch reminder by ID ensuring user isolation through Task relationship."""
        stmt = (
            select(Reminder)
            .join(Task, Reminder.task_id == Task.id)
            .where(
                Reminder.id == reminder_id,
                Reminder.is_deleted.is_(False),
                Task.user_id == user_id,
                Task.is_deleted.is_(False),
            )
        )
        return db.execute(stmt).scalar_one_or_none()

    def get_by_task_id(
        self, db: Session, task_id: uuid.UUID, user_id: uuid.UUID
    ) -> list[Reminder]:
        """Fetch all non-deleted reminders for a specific task."""
        stmt = (
            select(Reminder)
            .join(Task, Reminder.task_id == Task.id)
            .where(
                Reminder.task_id == task_id,
                Reminder.is_deleted.is_(False),
                Task.user_id == user_id,
                Task.is_deleted.is_(False),
            )
            .order_by(Reminder.remind_at.asc())
        )
        return list(db.execute(stmt).scalars().all())

    def get_user_reminders(
        self,
        db: Session,
        user_id: uuid.UUID,
        task_id: uuid.UUID | None = None,
        status: str | None = None,
        limit: int = 100,
    ) -> list[Reminder]:
        """Fetch all reminders for a user with optional task and status filters."""
        stmt = (
            select(Reminder)
            .join(Task, Reminder.task_id == Task.id)
            .where(
                Task.user_id == user_id,
                Task.is_deleted.is_(False),
                Reminder.is_deleted.is_(False),
            )
        )
        if task_id is not None:
            stmt = stmt.where(Reminder.task_id == task_id)
        if status is not None:
            stmt = stmt.where(Reminder.status == status.upper())

        stmt = stmt.order_by(Reminder.remind_at.asc()).limit(limit)
        return list(db.execute(stmt).scalars().all())

    def count_active_by_task(self, db: Session, task_id: uuid.UUID) -> int:
        """Count active scheduled reminders for a specific task."""
        stmt = select(Reminder).where(
            Reminder.task_id == task_id,
            Reminder.status == "SCHEDULED",
            Reminder.is_deleted.is_(False),
        )
        return len(list(db.execute(stmt).scalars().all()))

    def update(
        self, db: Session, reminder: Reminder, reminder_in: ReminderUpdate
    ) -> Reminder:
        """Update reminder properties."""
        now = datetime.now(UTC)
        if reminder_in.remind_at is not None:
            remind_at = reminder_in.remind_at
            if remind_at.tzinfo is None:
                remind_at = remind_at.replace(tzinfo=UTC)
            reminder.remind_at = remind_at

        if reminder_in.status is not None:
            reminder.status = reminder_in.status.value

        if reminder_in.notification_id is not None:
            reminder.notification_id = reminder_in.notification_id

        reminder.updated_at = now
        db.add(reminder)
        db.commit()
        db.refresh(reminder)
        return reminder

    def cancel_task_reminders(
        self, db: Session, task_id: uuid.UUID, user_id: uuid.UUID | None = None
    ) -> int:
        """Auto-cancel all SCHEDULED reminders for a task."""
        stmt = (
            select(Reminder)
            .where(
                Reminder.task_id == task_id,
                Reminder.status == "SCHEDULED",
                Reminder.is_deleted.is_(False),
            )
        )
        reminders = list(db.execute(stmt).scalars().all())
        now = datetime.now(UTC)
        for r in reminders:
            r.status = "CANCELLED"
            r.updated_at = now
            db.add(r)
        db.commit()
        return len(reminders)

    def delete(self, db: Session, reminder: Reminder) -> None:
        """Soft-delete a reminder and mark status as CANCELLED."""
        now = datetime.now(UTC)
        reminder.is_deleted = True
        reminder.status = "CANCELLED"
        reminder.updated_at = now
        db.add(reminder)
        db.commit()


reminder_repository = ReminderRepository()
