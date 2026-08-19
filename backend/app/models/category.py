import uuid

from sqlalchemy import ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import BaseDBModel


class Category(BaseDBModel):
    """
    Task Category entity definition for Priora.
    Complies with DB-001 (UUID), DB-002 (Timestamps), DB-003 (Soft delete).
    """
    __tablename__ = "categories"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )
    color: Mapped[str] = mapped_column(
        String(20),
        default="#2D6A4F",
        nullable=False,
    )
    icon: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )
