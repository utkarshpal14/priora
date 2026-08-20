import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.category import Category
from app.models.goal import Goal, GoalMilestone
from app.models.task import Task
from app.models.task_session import TaskSession
from app.schemas.goal import GoalStatus
from app.schemas.task import TaskPriority, TaskStatus


class AnalyticsRepository:
    def get_completed_tasks(
        self,
        db: Session,
        user_id: uuid.UUID,
    ) -> list[Task]:
        """Fetch all completed tasks for user to calculate streaks and stats."""
        stmt = (
            select(Task)
            .where(
                Task.user_id == user_id,
                Task.status == TaskStatus.COMPLETED,
                Task.completed_at.isnot(None),
            )
            .order_by(Task.completed_at.asc())
        )
        return list(db.scalars(stmt).all())

    def get_all_tasks(
        self,
        db: Session,
        user_id: uuid.UUID,
    ) -> list[Task]:
        """Fetch all tasks for user to compute overall completion rate and due breakdown."""
        stmt = select(Task).where(Task.user_id == user_id)
        return list(db.scalars(stmt).all())

    def get_goals_and_milestones_stats(
        self,
        db: Session,
        user_id: uuid.UUID,
    ) -> dict[str, Any]:
        """Compute active & completed goals and milestones stats."""
        goals_stmt = select(Goal).where(Goal.user_id == user_id)
        goals = list(db.scalars(goals_stmt).all())

        total_goals = len(goals)
        active_goals = sum(1 for g in goals if g.status == GoalStatus.IN_PROGRESS)
        completed_goals = sum(1 for g in goals if g.status == GoalStatus.COMPLETED)

        milestones_stmt = (
            select(GoalMilestone)
            .join(Goal, Goal.id == GoalMilestone.goal_id)
            .where(Goal.user_id == user_id)
        )
        milestones = list(db.scalars(milestones_stmt).all())

        total_milestones = len(milestones)
        completed_milestones = sum(1 for m in milestones if m.is_completed)

        return {
            "total_goals": total_goals,
            "active_goals": active_goals,
            "completed_goals": completed_goals,
            "goal_completion_rate": (completed_goals / total_goals * 100.0) if total_goals > 0 else 0.0,
            "total_milestones": total_milestones,
            "completed_milestones": completed_milestones,
            "milestone_completion_rate": (completed_milestones / total_milestones * 100.0) if total_milestones > 0 else 0.0,
        }

    def get_task_sessions_minutes(
        self,
        db: Session,
        user_id: uuid.UUID,
        start_utc: datetime,
        end_utc: datetime,
    ) -> int:
        """Calculate total minutes logged in TaskSession table between timestamps."""
        stmt = (
            select(TaskSession)
            .join(Task, Task.id == TaskSession.task_id)
            .where(
                Task.user_id == user_id,
                TaskSession.scheduled_start >= start_utc,
                TaskSession.scheduled_start <= end_utc,
            )
        )
        sessions = list(db.scalars(stmt).all())
        total_mins = 0
        for s in sessions:
            if s.scheduled_start and s.scheduled_end:
                diff = (s.scheduled_end - s.scheduled_start).total_seconds() / 60.0
                if diff > 0:
                    total_mins += int(diff)
        return total_mins

    def get_category_breakdown(
        self,
        db: Session,
        user_id: uuid.UUID,
    ) -> list[dict[str, Any]]:
        """Fetch count of completed tasks per category."""
        stmt = (
            select(
                Task.category_id,
                Category.name,
                Category.color,
                func.count(Task.id).label("task_count"),
            )
            .outerjoin(Category, Category.id == Task.category_id)
            .where(
                Task.user_id == user_id,
                Task.status == TaskStatus.COMPLETED,
            )
            .group_by(Task.category_id, Category.name, Category.color)
        )
        results = db.execute(stmt).all()
        return [
            {
                "category_id": r.category_id,
                "name": r.name or "Uncategorized",
                "color": r.color or "#6366F1",
                "count": r.task_count,
            }
            for r in results
        ]

    def get_priority_breakdown(
        self,
        db: Session,
        user_id: uuid.UUID,
    ) -> dict[str, int]:
        """Fetch count of completed tasks grouped by priority."""
        stmt = (
            select(Task.priority, func.count(Task.id))
            .where(
                Task.user_id == user_id,
                Task.status == TaskStatus.COMPLETED,
            )
            .group_by(Task.priority)
        )
        results = db.execute(stmt).all()
        counts = {
            TaskPriority.CRITICAL: 0,
            TaskPriority.HIGH: 0,
            TaskPriority.MEDIUM: 0,
            TaskPriority.LOW: 0,
        }
        for prio, cnt in results:
            if prio in counts:
                counts[prio] = cnt
        return counts


analytics_repository = AnalyticsRepository()
