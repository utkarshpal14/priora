import uuid
from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.attachment import Attachment
from app.models.goal import Goal
from app.models.task import Task
from app.models.user import User


class AttachmentRepository:
    def get_by_id(self, db: Session, attachment_id: uuid.UUID, user_id: uuid.UUID) -> Attachment | None:
        stmt = select(Attachment).where(
            Attachment.id == attachment_id,
            Attachment.user_id == user_id,
            Attachment.is_deleted.is_(False),
        )
        return db.scalar(stmt)

    def get_for_entity(
        self,
        db: Session,
        user_id: uuid.UUID,
        task_id: uuid.UUID | None = None,
        goal_id: uuid.UUID | None = None,
        milestone_id: uuid.UUID | None = None,
        tag: str | None = None,
    ) -> list[Attachment]:
        stmt = select(Attachment).where(
            Attachment.user_id == user_id,
            Attachment.is_deleted.is_(False),
        )

        if task_id:
            stmt = stmt.where(Attachment.task_id == task_id)
        elif goal_id:
            stmt = stmt.where(Attachment.goal_id == goal_id)
        elif milestone_id:
            stmt = stmt.where(Attachment.milestone_id == milestone_id)

        if tag:
            stmt = stmt.where(Attachment.tags.ilike(f"%{tag.strip()}%"))

        stmt = stmt.order_by(Attachment.is_pinned.desc(), Attachment.created_at.desc())
        return list(db.scalars(stmt).all())

    def search(
        self,
        db: Session,
        user_id: uuid.UUID,
        query: str,
        tag: str | None = None,
        type_filter: str | None = None,
    ) -> list[Attachment]:
        stmt = select(Attachment).where(
            Attachment.user_id == user_id,
            Attachment.is_deleted.is_(False),
        )

        q_clean = query.strip()
        if q_clean:
            stmt = stmt.where(
                (Attachment.name.ilike(f"%{q_clean}%"))
                | (Attachment.search_text.ilike(f"%{q_clean}%"))
                | (Attachment.original_filename.ilike(f"%{q_clean}%"))
                | (Attachment.tags.ilike(f"%{q_clean}%"))
            )

        if tag:
            stmt = stmt.where(Attachment.tags.ilike(f"%{tag.strip()}%"))

        if type_filter:
            stmt = stmt.where(Attachment.type == type_filter.upper())

        stmt = stmt.order_by(Attachment.is_pinned.desc(), Attachment.created_at.desc())
        return list(db.scalars(stmt).all())

    def count_for_entity(
        self,
        db: Session,
        user_id: uuid.UUID,
        task_id: uuid.UUID | None = None,
        goal_id: uuid.UUID | None = None,
        milestone_id: uuid.UUID | None = None,
    ) -> int:
        stmt = select(func.count(Attachment.id)).where(
            Attachment.user_id == user_id,
            Attachment.is_deleted.is_(False),
        )
        if task_id:
            stmt = stmt.where(Attachment.task_id == task_id)
        elif goal_id:
            stmt = stmt.where(Attachment.goal_id == goal_id)
        elif milestone_id:
            stmt = stmt.where(Attachment.milestone_id == milestone_id)

        return db.scalar(stmt) or 0

    def find_by_hash(self, db: Session, user_id: uuid.UUID, file_hash: str) -> Attachment | None:
        stmt = select(Attachment).where(
            Attachment.user_id == user_id,
            Attachment.file_hash == file_hash,
            Attachment.is_deleted.is_(False),
        )
        return db.scalar(stmt)

    def create(self, db: Session, attachment: Attachment) -> Attachment:
        db.add(attachment)

        # Increment cached attachment count on target entity
        if attachment.task_id:
            task = db.get(Task, attachment.task_id)
            if task:
                task.attachment_count = (task.attachment_count or 0) + 1
        elif attachment.goal_id:
            goal = db.get(Goal, attachment.goal_id)
            if goal:
                goal.attachment_count = (goal.attachment_count or 0) + 1

        # Increment user storage usage if file size exists
        if attachment.file_size_bytes and attachment.file_size_bytes > 0:
            user = db.get(User, attachment.user_id)
            if user:
                user.storage_used_bytes = (user.storage_used_bytes or 0) + attachment.file_size_bytes

        db.commit()
        db.refresh(attachment)
        return attachment

    def soft_delete(self, db: Session, attachment: Attachment) -> None:
        attachment.is_deleted = True
        attachment.updated_at = datetime.now(UTC)

        # Decrement cached attachment count on target entity
        if attachment.task_id:
            task = db.get(Task, attachment.task_id)
            if task and task.attachment_count > 0:
                task.attachment_count -= 1
        elif attachment.goal_id:
            goal = db.get(Goal, attachment.goal_id)
            if goal and goal.attachment_count > 0:
                goal.attachment_count -= 1

        # Decrement user storage usage
        if attachment.file_size_bytes and attachment.file_size_bytes > 0:
            user = db.get(User, attachment.user_id)
            if user and user.storage_used_bytes >= attachment.file_size_bytes:
                user.storage_used_bytes -= attachment.file_size_bytes

        db.commit()

    def toggle_pin(self, db: Session, attachment: Attachment) -> Attachment:
        attachment.is_pinned = not attachment.is_pinned
        attachment.updated_at = datetime.now(UTC)
        db.commit()
        db.refresh(attachment)
        return attachment


attachment_repository = AttachmentRepository()
