import uuid
from typing import TYPE_CHECKING

from sqlalchemy import BigInteger, Boolean, ForeignKey, Index, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import BaseDBModel

if TYPE_CHECKING:
    from app.models.goal import Goal, GoalMilestone
    from app.models.task import Task
    from app.models.user import User


class Attachment(BaseDBModel):
    """
    Attachment model supporting multi-entity resources:
    Images, Documents, Links, and Notes attached to Tasks, Goals, or Milestones.
    """
    __tablename__ = "attachments"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    task_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid,
        ForeignKey("tasks.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
    goal_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid,
        ForeignKey("goals.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
    milestone_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid,
        ForeignKey("goal_milestones.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    type: Mapped[str] = mapped_column(String(20), nullable=False)  # IMAGE, DOCUMENT, LINK, NOTE
    source_type: Mapped[str] = mapped_column(String(20), default="UPLOAD", nullable=False)  # UPLOAD, LINK, NOTE
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    original_filename: Mapped[str | None] = mapped_column(String(255), nullable=True)
    file_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    thumbnail_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    url: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    thumbnail_url: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    domain: Mapped[str | None] = mapped_column(String(150), nullable=True)
    site_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    favicon_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    content: Mapped[str | None] = mapped_column(Text, nullable=True)
    tags: Mapped[str | None] = mapped_column(String(500), nullable=True)
    file_hash: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    mime_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    file_size_bytes: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    is_pinned: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    search_text: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="attachments")
    task: Mapped["Task | None"] = relationship("Task", back_populates="attachments")
    goal: Mapped["Goal | None"] = relationship("Goal", back_populates="attachments")
    milestone: Mapped["GoalMilestone | None"] = relationship("GoalMilestone", back_populates="attachments")

    __table_args__ = (
        Index("ix_attachments_user_entity", "user_id", "task_id", "goal_id", "milestone_id"),
    )
