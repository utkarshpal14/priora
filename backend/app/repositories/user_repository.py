import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User


class UserRepository:
    """Repository handling database operations for the User entity."""

    def get_by_id(self, db: Session, user_id: uuid.UUID) -> User | None:
        """Fetch active user by primary key UUID."""
        statement = select(User).where(User.id == user_id, User.is_deleted.is_(False))
        return db.scalars(statement).first()

    def get_by_email(self, db: Session, email: str) -> User | None:
        """Fetch active user by unique email address."""
        statement = select(User).where(
            User.email == email.lower().strip(),
            User.is_deleted.is_(False),
        )
        return db.scalars(statement).first()

    def create(self, db: Session, user: User) -> User:
        """Persist a new User entity to the database."""
        user.email = user.email.lower().strip()
        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    def update(self, db: Session, user: User, update_data: dict[str, Any]) -> User:
        """Update fields on an existing User entity."""
        for field, value in update_data.items():
            if hasattr(user, field):
                setattr(user, field, value)
        db.commit()
        db.refresh(user)
        return user

    def soft_delete(self, db: Session, user: User) -> User:
        """Soft-delete a user entity (DB-003)."""
        user.is_deleted = True
        db.commit()
        db.refresh(user)
        return user


user_repository = UserRepository()
