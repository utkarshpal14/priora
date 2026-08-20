import uuid
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import BaseDBModel

if TYPE_CHECKING:
    from app.models.user import User


class DeviceToken(BaseDBModel):
    """
    DeviceToken model storing FCM/APNs push registration tokens per device.
    """
    __tablename__ = "device_tokens"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    token: Mapped[str] = mapped_column(
        String(500),
        nullable=False,
        unique=True,
        index=True,
    )
    platform: Mapped[str] = mapped_column(
        String(20),
        default="android",
        nullable=False,
    )  # android, ios, web

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="device_tokens")
