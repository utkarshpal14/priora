import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import BaseDBModel
from app.models.category import Category

if TYPE_CHECKING:
    from app.models.goal import Goal, GoalMilestone
    from app.models.reminder import Reminder
    from app.models.task_session import TaskSession


class Task(BaseDBModel):
    """
    Task entity definition for Priora.
    Complies with DB-001 (UUID), DB-002 (Timestamps), DB-003 (Soft delete).
    """
    __tablename__ = "tasks"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    category_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid,
        ForeignKey("categories.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    goal_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid,
        ForeignKey("goals.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    milestone_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid,
        ForeignKey("goal_milestones.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    title: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )
    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )
    priority: Mapped[str] = mapped_column(
        String(20),
        default="MEDIUM",
        nullable=False,
        index=True,
    )  # LOW, MEDIUM, HIGH, CRITICAL
    status: Mapped[str] = mapped_column(
        String(20),
        default="PENDING",
        nullable=False,
        index=True,
    )  # PENDING, IN_PROGRESS, COMPLETED, CANCELLED
    deadline: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )
    scheduled_start: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )
    scheduled_end: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )
    estimated_minutes: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # Relationships
    category: Mapped[Category | None] = relationship("Category", lazy="joined")
    goal: Mapped["Goal | None"] = relationship("Goal", back_populates="tasks")
    milestone: Mapped["GoalMilestone | None"] = relationship("GoalMilestone", back_populates="tasks")
    reminders: Mapped[list["Reminder"]] = relationship(
        "Reminder",
        back_populates="task",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    sessions: Mapped[list["TaskSession"]] = relationship(
        "TaskSession",
        back_populates="task",
        cascade="all, delete-orphan",
        lazy="selectin",
    )

