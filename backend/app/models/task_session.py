import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import BaseDBModel

if TYPE_CHECKING:
    from app.models.task import Task


class TaskSession(BaseDBModel):
    """
    TaskSession model representing planned time-block focus sessions for a task.
    Enables multi-session scheduling (e.g. Mon 10-12, Wed 2-4).
    """
    __tablename__ = "task_sessions"

    task_id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        ForeignKey("tasks.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    scheduled_start: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        index=True,
    )
    scheduled_end: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        index=True,
    )

    # Relationships
    task: Mapped["Task"] = relationship("Task", back_populates="sessions")
