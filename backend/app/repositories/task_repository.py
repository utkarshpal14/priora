import uuid
from datetime import UTC, datetime

from sqlalchemy import case, func, or_, select
from sqlalchemy.orm import Session

from app.models.task import Task
from app.schemas.task import TaskCreate, TaskMetrics, TaskUpdate


class TaskRepository:
    """Repository handling database operations for the Task entity."""

    def get_by_id(
        self, db: Session, task_id: uuid.UUID, user_id: uuid.UUID
    ) -> Task | None:
        """Fetch active task by ID strictly isolated by user (SEC-003, DB-003)."""
        stmt = select(Task).where(
            Task.id == task_id,
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
        )
        return db.scalars(stmt).first()

    def get_tasks(
        self,
        db: Session,
        user_id: uuid.UUID,
        status: str | None = None,
        priority: str | None = None,
        category_id: uuid.UUID | None = None,
        search: str | None = None,
        limit: int = 100,
    ) -> list[Task]:
        """
        Fetch tasks with priority-first & nearest-deadline sorting,
        optional search, and category/status/priority filters.
        """
        now = datetime.now(UTC)
        stmt = select(Task).where(
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
        )

        if status:
            if status.upper() == "OVERDUE":
                stmt = stmt.where(
                    Task.status.notin_(["COMPLETED", "CANCELLED"]),
                    Task.deadline.is_not(None),
                    Task.deadline < now,
                )
            else:
                stmt = stmt.where(Task.status == status.upper())

        if priority:
            stmt = stmt.where(Task.priority == priority.upper())

        if category_id:
            stmt = stmt.where(Task.category_id == category_id)

        if search and search.strip():
            term = f"%{search.strip()}%"
            stmt = stmt.where(
                or_(
                    Task.title.ilike(term),
                    Task.description.ilike(term),
                )
            )

        # Composite ranking formula:
        # 1. Overdue + Critical
        # 2. Overdue + High
        # 3. Overdue + Medium
        # 4. Overdue + Low
        # 5. Critical (Future / No deadline)
        # 6. High
        # 7. Medium
        # 8. Low
        is_overdue_cond = (
            Task.deadline.is_not(None)
            & (Task.deadline < now)
            & Task.status.notin_(["COMPLETED", "CANCELLED"])
        )

        priority_order = case(
            (is_overdue_cond & (Task.priority == "CRITICAL"), 1),
            (is_overdue_cond & (Task.priority == "HIGH"), 2),
            (is_overdue_cond & (Task.priority == "MEDIUM"), 3),
            (is_overdue_cond & (Task.priority == "LOW"), 4),
            (Task.priority == "CRITICAL", 5),
            (Task.priority == "HIGH", 6),
            (Task.priority == "MEDIUM", 7),
            (Task.priority == "LOW", 8),
            else_=9,
        )

        stmt = stmt.order_by(
            priority_order.asc(),
            Task.deadline.asc().nullslast(),
            Task.created_at.desc(),
        ).limit(limit)

        return list(db.scalars(stmt).all())

    def get_metrics(self, db: Session, user_id: uuid.UUID) -> TaskMetrics:
        """Calculate total, completed, pending, overdue, and due_today metrics for active tasks."""
        now = datetime.now(UTC)
        start_of_day = datetime(now.year, now.month, now.day, 0, 0, 0, tzinfo=UTC)
        end_of_day = datetime(now.year, now.month, now.day, 23, 59, 59, 999999, tzinfo=UTC)

        total_stmt = select(func.count(Task.id)).where(
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
        )
        total = db.scalar(total_stmt) or 0

        completed_stmt = select(func.count(Task.id)).where(
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
            Task.status == "COMPLETED",
        )
        completed = db.scalar(completed_stmt) or 0

        pending = max(0, total - completed)

        overdue_stmt = select(func.count(Task.id)).where(
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
            Task.status.notin_(["COMPLETED", "CANCELLED"]),
            Task.deadline.is_not(None),
            Task.deadline < now,
        )
        overdue = db.scalar(overdue_stmt) or 0

        due_today_stmt = select(func.count(Task.id)).where(
            Task.user_id == user_id,
            Task.is_deleted.is_(False),
            Task.status.notin_(["COMPLETED", "CANCELLED"]),
            Task.deadline.is_not(None),
            Task.deadline >= start_of_day,
            Task.deadline <= end_of_day,
        )
        due_today = db.scalar(due_today_stmt) or 0

        return TaskMetrics(
            total=total,
            completed=completed,
            pending=pending,
            overdue=overdue,
            due_today=due_today,
        )

    def create(self, db: Session, task_in: TaskCreate, user_id: uuid.UUID) -> Task:
        """Create a new task with immutable ownership (user_id)."""
        task = Task(
            user_id=user_id,
            category_id=task_in.category_id,
            goal_id=task_in.goal_id,
            milestone_id=task_in.milestone_id,
            title=task_in.title.strip(),
            description=task_in.description.strip() if task_in.description else None,
            priority=task_in.priority.value,
            status="PENDING",
            deadline=task_in.deadline,
            scheduled_start=task_in.scheduled_start,
            scheduled_end=task_in.scheduled_end,
            estimated_minutes=task_in.estimated_minutes,
            repeat_type=task_in.repeat_type.lower() if task_in.repeat_type else "none",
            repeat_interval=task_in.repeat_interval or 1,
            repeat_end_date=task_in.repeat_end_date,
        )
        db.add(task)
        db.commit()
        db.refresh(task)

        # Auto-create session if both start and end times provided
        if task_in.scheduled_start and task_in.scheduled_end:
            from app.models.task_session import TaskSession
            session = TaskSession(
                task_id=task.id,
                scheduled_start=task_in.scheduled_start,
                scheduled_end=task_in.scheduled_end,
            )
            db.add(session)
            db.commit()
            db.refresh(task)

        return task

    def update(self, db: Session, task: Task, task_in: TaskUpdate) -> Task:
        """Update task properties without permitting user_id mutations."""
        if task_in.title is not None:
            task.title = task_in.title.strip()
        if task_in.description is not None:
            task.description = task_in.description.strip() if task_in.description else None
        if task_in.priority is not None:
            task.priority = task_in.priority.value
        if task_in.status is not None:
            task.status = task_in.status.value
            if task_in.status.value == "COMPLETED" and not task.completed_at:
                task.completed_at = datetime.now(UTC)
            elif task_in.status.value != "COMPLETED":
                task.completed_at = None
        if task_in.category_id is not None:
            task.category_id = task_in.category_id
        if task_in.goal_id is not None:
            task.goal_id = task_in.goal_id
        if task_in.milestone_id is not None:
            task.milestone_id = task_in.milestone_id
        if task_in.deadline is not None:
            task.deadline = task_in.deadline
        if task_in.scheduled_start is not None:
            task.scheduled_start = task_in.scheduled_start
        if task_in.scheduled_end is not None:
            task.scheduled_end = task_in.scheduled_end
        if task_in.estimated_minutes is not None:
            task.estimated_minutes = task_in.estimated_minutes
        if task_in.repeat_type is not None:
            task.repeat_type = task_in.repeat_type.lower()
        if task_in.repeat_interval is not None:
            task.repeat_interval = task_in.repeat_interval
        if task_in.repeat_end_date is not None:
            task.repeat_end_date = task_in.repeat_end_date

        db.add(task)
        db.commit()
        db.refresh(task)
        return task

    def complete(self, db: Session, task: Task) -> Task:
        """Mark task as COMPLETED and set completed_at timestamp."""
        task.status = "COMPLETED"
        task.completed_at = datetime.now(UTC)
        db.add(task)
        db.commit()
        db.refresh(task)
        return task

    def reopen(self, db: Session, task: Task) -> Task:
        """Reopen a completed task to PENDING."""
        task.status = "PENDING"
        task.completed_at = None
        db.add(task)
        db.commit()
        db.refresh(task)
        return task

    def delete(self, db: Session, task: Task) -> None:
        """Soft delete task (DB-003)."""
        task.is_deleted = True
        db.add(task)
        db.commit()


task_repository = TaskRepository()
