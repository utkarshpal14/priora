import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Integer, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import BaseDBModel

if TYPE_CHECKING:
    from app.models.task import Task


class Reminder(BaseDBModel):
    """
    Reminder entity definition for Priora.
    Ownership is derived through Task (task.user_id).
    Complies with DB-001 (UUID), DB-002 (Timestamps), DB-003 (Soft delete).
    """
    __tablename__ = "reminders"

    task_id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        ForeignKey("tasks.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    notification_id: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
        index=True,
    )
    remind_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        index=True,
    )
    status: Mapped[str] = mapped_column(
        String(20),
        default="SCHEDULED",
        nullable=False,
        index=True,
    )  # SCHEDULED, SENT, CANCELLED

    # Relationships
    task: Mapped["Task"] = relationship("Task", back_populates="reminders")
