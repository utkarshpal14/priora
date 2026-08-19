import uuid
from datetime import UTC, datetime

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.goal import Goal, GoalMilestone
from app.repositories.goal_repository import goal_repository
from app.schemas.category import CategoryRead
from app.schemas.goal import (
    GoalActivityItem,
    GoalCreate,
    GoalDetailRead,
    GoalListResponse,
    GoalMilestoneCreate,
    GoalMilestoneRead,
    GoalMilestoneUpdate,
    GoalRead,
    GoalStatus,
    GoalUpdate,
)
from app.schemas.task import TaskRead, TaskStatus


def _to_utc(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt.astimezone(UTC)


class GoalService:
    """Business logic service for Goals and Milestones management."""

    def _calculate_metrics(self, goal: Goal) -> tuple[float, int, int, int, int]:
        active_milestones = [m for m in goal.milestones if not m.is_deleted]
        active_tasks = [t for t in goal.tasks if not t.is_deleted]

        completed_milestones = [m for m in active_milestones if m.is_completed]
        completed_tasks = [t for t in active_tasks if t.status == TaskStatus.COMPLETED.value]

        m_count = len(active_milestones)
        m_done = len(completed_milestones)
        t_count = len(active_tasks)
        t_done = len(completed_tasks)

        total_items = m_count + t_count
        completed_items = m_done + t_done

        progress = (
            round((completed_items / total_items * 100.0), 1)
            if total_items > 0
            else 0.0
        )
        return progress, m_count, m_done, t_count, t_done

    def _build_recent_activity(self, goal: Goal) -> list[GoalActivityItem]:
        activities: list[GoalActivityItem] = []

        active_milestones = [m for m in goal.milestones if not m.is_deleted]
        active_tasks = [t for t in goal.tasks if not t.is_deleted]

        for m in active_milestones:
            if m.is_completed:
                activities.append(
                    GoalActivityItem(
                        id=f"milestone-{m.id}",
                        type="MILESTONE",
                        title=m.title,
                        completed_at=_to_utc(m.updated_at) or datetime.now(UTC),
                        description=m.description,
                    )
                )

        for t in active_tasks:
            if t.status == TaskStatus.COMPLETED.value:
                activities.append(
                    GoalActivityItem(
                        id=f"task-{t.id}",
                        type="TASK",
                        title=t.title,
                        completed_at=_to_utc(t.completed_at) or _to_utc(t.updated_at) or datetime.now(UTC),
                        description=t.description,
                    )
                )

        activities.sort(key=lambda a: a.completed_at, reverse=True)
        return activities[:10]

    def _to_goal_read(self, goal: Goal) -> GoalRead:
        progress, m_count, m_done, t_count, t_done = self._calculate_metrics(goal)
        category_read = CategoryRead.model_validate(goal.category) if goal.category else None

        return GoalRead(
            id=goal.id,
            user_id=goal.user_id,
            title=goal.title,
            description=goal.description,
            target_date=goal.target_date,
            category_id=goal.category_id,
            category=category_read,
            status=GoalStatus(goal.status),
            color=goal.color,
            icon=goal.icon,
            progress_percentage=progress,
            milestones_count=m_count,
            completed_milestones_count=m_done,
            tasks_count=t_count,
            completed_tasks_count=t_done,
            created_at=goal.created_at,
            updated_at=goal.updated_at,
        )

    def _to_goal_detail(self, goal: Goal) -> GoalDetailRead:
        base_read = self._to_goal_read(goal)
        active_milestones = [m for m in goal.milestones if not m.is_deleted]
        active_tasks = [t for t in goal.tasks if not t.is_deleted]

        milestone_reads = [GoalMilestoneRead.model_validate(m) for m in active_milestones]
        task_reads = [TaskRead.model_validate(t) for t in active_tasks]
        activity = self._build_recent_activity(goal)

        return GoalDetailRead(
            **base_read.model_dump(),
            milestones=milestone_reads,
            tasks=task_reads,
            recent_activity=activity,
        )

    def get_goals(
        self, db: Session, user_id: uuid.UUID, status_filter: str | None = None
    ) -> GoalListResponse:
        goals = goal_repository.get_all(db, user_id, status=status_filter)
        goal_reads = [self._to_goal_read(g) for g in goals]

        all_goals = goal_repository.get_all(db, user_id)
        active_count = sum(1 for g in all_goals if g.status == GoalStatus.IN_PROGRESS.value)
        completed_count = sum(1 for g in all_goals if g.status == GoalStatus.COMPLETED.value)

        return GoalListResponse(
            goals=goal_reads,
            total=len(goal_reads),
            active_count=active_count,
            completed_count=completed_count,
        )

    def get_goal_detail(self, db: Session, goal_id: uuid.UUID, user_id: uuid.UUID) -> GoalDetailRead:
        goal = goal_repository.get_by_id(db, goal_id, user_id)
        if not goal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Goal not found.",
            )
        return self._to_goal_detail(goal)

    def create_goal(self, db: Session, goal_in: GoalCreate, user_id: uuid.UUID) -> GoalDetailRead:
        goal = goal_repository.create(db, goal_in, user_id)
        return self._to_goal_detail(goal)

    def update_goal(
        self, db: Session, goal_id: uuid.UUID, goal_in: GoalUpdate, user_id: uuid.UUID
    ) -> GoalDetailRead:
        goal = goal_repository.get_by_id(db, goal_id, user_id)
        if not goal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Goal not found.",
            )
        updated = goal_repository.update(db, goal, goal_in)
        return self._to_goal_detail(updated)

    def delete_goal(self, db: Session, goal_id: uuid.UUID, user_id: uuid.UUID) -> None:
        goal = goal_repository.get_by_id(db, goal_id, user_id)
        if not goal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Goal not found.",
            )
        goal_repository.delete(db, goal)

    def add_milestone(
        self,
        db: Session,
        goal_id: uuid.UUID,
        milestone_in: GoalMilestoneCreate,
        user_id: uuid.UUID,
    ) -> GoalMilestoneRead:
        goal = goal_repository.get_by_id(db, goal_id, user_id)
        if not goal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Goal not found.",
            )
        milestone = goal_repository.add_milestone(db, goal.id, milestone_in)
        return GoalMilestoneRead.model_validate(milestone)

    def toggle_milestone(
        self,
        db: Session,
        goal_id: uuid.UUID,
        milestone_id: uuid.UUID,
        user_id: uuid.UUID,
    ) -> GoalMilestoneRead:
        goal = goal_repository.get_by_id(db, goal_id, user_id)
        if not goal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Goal not found.",
            )
        milestone = goal_repository.get_milestone_by_id(db, milestone_id, goal.id)
        if not milestone:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Milestone not found.",
            )
        toggled = goal_repository.toggle_milestone(db, milestone)

        # Check if all items done to auto-complete goal
        db.refresh(goal)
        progress, _, _, _, _ = self._calculate_metrics(goal)
        if progress == 100.0 and goal.status == GoalStatus.IN_PROGRESS.value:
            goal.status = GoalStatus.COMPLETED.value
            db.commit()

        return GoalMilestoneRead.model_validate(toggled)

    def delete_milestone(
        self,
        db: Session,
        goal_id: uuid.UUID,
        milestone_id: uuid.UUID,
        user_id: uuid.UUID,
    ) -> None:
        goal = goal_repository.get_by_id(db, goal_id, user_id)
        if not goal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Goal not found.",
            )
        milestone = goal_repository.get_milestone_by_id(db, milestone_id, goal.id)
        if not milestone:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Milestone not found.",
            )
        goal_repository.delete_milestone(db, milestone)


goal_service = GoalService()
