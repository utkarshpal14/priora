import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.task import Task
from app.models.task_session import TaskSession


class TaskSessionRepository:
    """Repository handling database operations for TaskSessions (hourly focus blocks)."""

    def create(
        self,
        db: Session,
        task_id: uuid.UUID,
        scheduled_start: datetime,
        scheduled_end: datetime,
    ) -> TaskSession:
        session = TaskSession(
            task_id=task_id,
            scheduled_start=scheduled_start,
            scheduled_end=scheduled_end,
        )
        db.add(session)
        db.commit()
        db.refresh(session)
        return session

    def get_by_id(
        self, db: Session, session_id: uuid.UUID, user_id: uuid.UUID
    ) -> TaskSession | None:
        stmt = (
            select(TaskSession)
            .join(Task, TaskSession.task_id == Task.id)
            .where(
                TaskSession.id == session_id,
                Task.user_id == user_id,
                TaskSession.is_deleted.is_(False),
                Task.is_deleted.is_(False),
            )
            .options(selectinload(TaskSession.task))
        )
        return db.scalar(stmt)

    def get_for_user_on_date(
        self,
        db: Session,
        user_id: uuid.UUID,
        start_of_day: datetime,
        end_of_day: datetime,
    ) -> list[TaskSession]:
        stmt = (
            select(TaskSession)
            .join(Task, TaskSession.task_id == Task.id)
            .where(
                Task.user_id == user_id,
                TaskSession.is_deleted.is_(False),
                Task.is_deleted.is_(False),
                TaskSession.scheduled_start >= start_of_day,
                TaskSession.scheduled_start <= end_of_day,
            )
            .options(selectinload(TaskSession.task))
            .order_by(TaskSession.scheduled_start.asc())
        )
        return list(db.scalars(stmt).all())

    def update(
        self,
        db: Session,
        session: TaskSession,
        scheduled_start: datetime | None,
        scheduled_end: datetime | None,
    ) -> TaskSession:
        if scheduled_start is not None:
            session.scheduled_start = scheduled_start
        if scheduled_end is not None:
            session.scheduled_end = scheduled_end
        session.updated_at = datetime.now(UTC)
        db.add(session)
        db.commit()
        db.refresh(session)
        return session

    def delete(self, db: Session, session: TaskSession) -> None:
        session.is_deleted = True
        session.updated_at = datetime.now(UTC)
        db.add(session)
        db.commit()


task_session_repository = TaskSessionRepository()
