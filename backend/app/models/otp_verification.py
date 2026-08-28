import uuid
from datetime import datetime
from sqlalchemy import Boolean, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import BaseDBModel


class OtpVerification(BaseDBModel):
    """
    Model representing hashed OTP records for email verification and password resets.
    Security: Stores SHA-256 hashed code instead of raw 6-digit plain text.
    """
    __tablename__ = "otp_verifications"

    email: Mapped[str] = mapped_column(
        String(255),
        index=True,
        nullable=False,
    )
    otp_hash: Mapped[str] = mapped_column(
        String(128),
        nullable=False,
    )
    purpose: Mapped[str] = mapped_column(
        String(32),
        default="email_verification",
        nullable=False,
    )
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    is_used: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )
    attempts: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False,
    )
