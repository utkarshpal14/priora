import uuid
from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Date, ForeignKey, Integer, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import BaseDBModel

if TYPE_CHECKING:
    from app.models.category import Category
    from app.models.task import Task
    from app.models.user import User


class Goal(BaseDBModel):
    """
    Goal model representing long-term targets and roadmaps.
    """
    __tablename__ = "goals"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    category_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid,
        ForeignKey("categories.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    target_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[str] = mapped_column(
        String(50),
        default="IN_PROGRESS",
        nullable=False,
        index=True,
    )
    color: Mapped[str | None] = mapped_column(String(50), default="#6366F1", nullable=True)
    icon: Mapped[str | None] = mapped_column(String(50), default="flag_rounded", nullable=True)

    # Relationships
    user: Mapped["User"] = relationship("User")
    category: Mapped["Category | None"] = relationship("Category")
    milestones: Mapped[list["GoalMilestone"]] = relationship(
        "GoalMilestone",
        back_populates="goal",
        cascade="all, delete-orphan",
        order_by="GoalMilestone.order_index",
    )
    tasks: Mapped[list["Task"]] = relationship(
        "Task",
        back_populates="goal",
    )


class GoalMilestone(BaseDBModel):
    """
    Milestone model representing intermediate phases/checkpoints of a Goal.
    """
    __tablename__ = "goal_milestones"

    goal_id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        ForeignKey("goals.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    target_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    order_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Relationships
    goal: Mapped["Goal"] = relationship("Goal", back_populates="milestones")
    tasks: Mapped[list["Task"]] = relationship(
        "Task",
        back_populates="milestone",
    )
