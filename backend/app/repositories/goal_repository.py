import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.goal import Goal, GoalMilestone
from app.models.task import Task
from app.schemas.goal import GoalCreate, GoalMilestoneCreate, GoalMilestoneUpdate, GoalUpdate


class GoalRepository:
    """Repository handling database operations for Goals and GoalMilestones."""

    def get_by_id(self, db: Session, goal_id: uuid.UUID, user_id: uuid.UUID) -> Goal | None:
        """Fetch active goal by id for specific user with eager-loaded relationships."""
        stmt = (
            select(Goal)
            .where(
                Goal.id == goal_id,
                Goal.user_id == user_id,
                Goal.is_deleted.is_(False),
            )
            .options(
                selectinload(Goal.milestones.and_(GoalMilestone.is_deleted.is_(False))),
                selectinload(Goal.tasks.and_(Task.is_deleted.is_(False))),
                selectinload(Goal.category),
            )
        )
        return db.scalar(stmt)

    def get_all(
        self, db: Session, user_id: uuid.UUID, status: str | None = None
    ) -> list[Goal]:
        """Fetch all active goals for user, optionally filtered by status."""
        stmt = (
            select(Goal)
            .where(
                Goal.user_id == user_id,
                Goal.is_deleted.is_(False),
            )
            .options(
                selectinload(Goal.milestones.and_(GoalMilestone.is_deleted.is_(False))),
                selectinload(Goal.tasks.and_(Task.is_deleted.is_(False))),
                selectinload(Goal.category),
            )
            .order_by(Goal.created_at.desc())
        )
        if status:
            stmt = stmt.where(Goal.status == status.upper())
        return list(db.scalars(stmt).all())

    def create(self, db: Session, goal_in: GoalCreate, user_id: uuid.UUID) -> Goal:
        """Create a new goal and its optional initial milestones."""
        goal = Goal(
            user_id=user_id,
            category_id=goal_in.category_id,
            title=goal_in.title.strip(),
            description=goal_in.description.strip() if goal_in.description else None,
            target_date=goal_in.target_date,
            status=goal_in.status.value,
            color=goal_in.color,
            icon=goal_in.icon,
        )
        db.add(goal)
        db.flush()

        for idx, m_in in enumerate(goal_in.milestones):
            milestone = GoalMilestone(
                goal_id=goal.id,
                title=m_in.title.strip(),
                description=m_in.description.strip() if m_in.description else None,
                target_date=m_in.target_date,
                is_completed=False,
                order_index=m_in.order_index if m_in.order_index != 0 else idx,
            )
            db.add(milestone)

        db.commit()
        db.refresh(goal)
        return self.get_by_id(db, goal.id, user_id) or goal

    def update(self, db: Session, goal: Goal, goal_in: GoalUpdate) -> Goal:
        """Update goal fields."""
        if goal_in.title is not None:
            goal.title = goal_in.title.strip()
        if goal_in.description is not None:
            goal.description = goal_in.description.strip() if goal_in.description else None
        if goal_in.target_date is not None:
            goal.target_date = goal_in.target_date
        if goal_in.category_id is not None:
            goal.category_id = goal_in.category_id
        if goal_in.status is not None:
            goal.status = goal_in.status.value
        if goal_in.color is not None:
            goal.color = goal_in.color
        if goal_in.icon is not None:
            goal.icon = goal_in.icon

        goal.updated_at = datetime.now(UTC)
        db.add(goal)
        db.commit()
        db.refresh(goal)
        return goal

    def delete(self, db: Session, goal: Goal) -> None:
        """Soft delete goal."""
        goal.is_deleted = True
        goal.updated_at = datetime.now(UTC)
        db.add(goal)
        db.commit()

    # ----------------- Milestone Operations -----------------

    def get_milestone_by_id(
        self, db: Session, milestone_id: uuid.UUID, goal_id: uuid.UUID
    ) -> GoalMilestone | None:
        """Fetch milestone by id for a goal."""
        stmt = select(GoalMilestone).where(
            GoalMilestone.id == milestone_id,
            GoalMilestone.goal_id == goal_id,
            GoalMilestone.is_deleted.is_(False),
        )
        return db.scalar(stmt)

    def add_milestone(
        self, db: Session, goal_id: uuid.UUID, milestone_in: GoalMilestoneCreate
    ) -> GoalMilestone:
        """Add milestone to goal."""
        milestone = GoalMilestone(
            goal_id=goal_id,
            title=milestone_in.title.strip(),
            description=milestone_in.description.strip() if milestone_in.description else None,
            target_date=milestone_in.target_date,
            is_completed=False,
            order_index=milestone_in.order_index,
        )
        db.add(milestone)
        db.commit()
        db.refresh(milestone)
        return milestone

    def update_milestone(
        self,
        db: Session,
        milestone: GoalMilestone,
        milestone_in: GoalMilestoneUpdate,
    ) -> GoalMilestone:
        """Update milestone fields."""
        if milestone_in.title is not None:
            milestone.title = milestone_in.title.strip()
        if milestone_in.description is not None:
            milestone.description = milestone_in.description.strip() if milestone_in.description else None
        if milestone_in.target_date is not None:
            milestone.target_date = milestone_in.target_date
        if milestone_in.is_completed is not None:
            milestone.is_completed = milestone_in.is_completed
        if milestone_in.order_index is not None:
            milestone.order_index = milestone_in.order_index

        milestone.updated_at = datetime.now(UTC)
        db.add(milestone)
        db.commit()
        db.refresh(milestone)
        return milestone

    def toggle_milestone(self, db: Session, milestone: GoalMilestone) -> GoalMilestone:
        """Toggle milestone completion state."""
        milestone.is_completed = not milestone.is_completed
        milestone.updated_at = datetime.now(UTC)
        db.add(milestone)
        db.commit()
        db.refresh(milestone)
        return milestone

    def delete_milestone(self, db: Session, milestone: GoalMilestone) -> None:
        """Soft delete milestone."""
        milestone.is_deleted = True
        milestone.updated_at = datetime.now(UTC)
        db.add(milestone)
        db.commit()


goal_repository = GoalRepository()
