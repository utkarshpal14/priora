from typing import TYPE_CHECKING
from sqlalchemy import BigInteger, Boolean, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import BaseDBModel

if TYPE_CHECKING:
    from app.models.attachment import Attachment


class User(BaseDBModel):
    """
    User entity definition for Priora.
    Complies with DB-001 (UUID), DB-002 (Timestamps), DB-003 (Soft delete), and Document 11.
    """
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        index=True,
        nullable=False,
    )
    hashed_password: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )
    full_name: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )
    avatar_url: Mapped[str | None] = mapped_column(
        String(512),
        nullable=True,
    )
    auth_provider: Mapped[str] = mapped_column(
        String(20),
        default="email",
        nullable=False,
    )
    is_email_verified: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )
    storage_used_bytes: Mapped[int] = mapped_column(
        BigInteger,
        default=0,
        nullable=False,
    )
    token_version: Mapped[int] = mapped_column(
        Integer,
        default=1,
        nullable=False,
    )

    # Notification preferences
    notifications_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    sound_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    deadline_reminders: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    session_reminders: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    review_reminders: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    goal_alerts: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    attachments: Mapped[list["Attachment"]] = relationship(
        "Attachment",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    device_tokens: Mapped[list["DeviceToken"]] = relationship(
        "DeviceToken",
        back_populates="user",
        cascade="all, delete-orphan",
    )
