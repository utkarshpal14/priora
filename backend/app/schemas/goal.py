import uuid
from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.category import CategoryRead
from app.schemas.task import TaskRead


class GoalStatus(str, Enum):
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    PAUSED = "PAUSED"
    ARCHIVED = "ARCHIVED"


# -------------------- Milestone Schemas --------------------

class GoalMilestoneBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: str | None = None
    target_date: date | None = None
    order_index: int = 0


class GoalMilestoneCreate(GoalMilestoneBase):
    pass


class GoalMilestoneUpdate(BaseModel):
    title: str | None = Field(None, min_length=1, max_length=255)
    description: str | None = None
    target_date: date | None = None
    is_completed: bool | None = None
    order_index: int | None = None


class GoalMilestoneRead(GoalMilestoneBase):
    id: uuid.UUID
    goal_id: uuid.UUID
    is_completed: bool
    attachment_count: int = 0
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# -------------------- Activity Schema --------------------

class GoalActivityItem(BaseModel):
    id: str
    type: str  # "MILESTONE" or "TASK"
    title: str
    completed_at: datetime
    description: str | None = None


# -------------------- Goal Schemas --------------------

class GoalBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: str | None = None
    target_date: date | None = None
    category_id: uuid.UUID | None = None
    status: GoalStatus = GoalStatus.IN_PROGRESS
    color: str | None = "#6366F1"
    icon: str | None = "flag_rounded"


class GoalCreate(GoalBase):
    milestones: list[GoalMilestoneCreate] = []


class GoalUpdate(BaseModel):
    title: str | None = Field(None, min_length=1, max_length=255)
    description: str | None = None
    target_date: date | None = None
    category_id: uuid.UUID | None = None
    status: GoalStatus | None = None
    color: str | None = None
    icon: str | None = None


class GoalRead(GoalBase):
    id: uuid.UUID
    user_id: uuid.UUID
    progress_percentage: float = 0.0
    milestones_count: int = 0
    completed_milestones_count: int = 0
    tasks_count: int = 0
    completed_tasks_count: int = 0
    attachment_count: int = 0
    category: CategoryRead | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class GoalDetailRead(GoalRead):
    milestones: list[GoalMilestoneRead] = []
    tasks: list[TaskRead] = []
    recent_activity: list[GoalActivityItem] = []


class GoalListResponse(BaseModel):
    goals: list[GoalRead]
    total: int
    active_count: int
    completed_count: int
