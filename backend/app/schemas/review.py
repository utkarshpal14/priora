import uuid
from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field

from app.schemas.task import TaskRead


class RescheduleAction(str, Enum):
    MOVE_TOMORROW = "MOVE_TOMORROW"
    MOVE_NEXT_WEEK = "MOVE_NEXT_WEEK"
    SCHEDULE = "SCHEDULE"
    COMPLETE = "COMPLETE"
    CANCEL = "CANCEL"


class RescheduleItem(BaseModel):
    task_id: uuid.UUID
    action: RescheduleAction
    new_deadline: datetime | None = Field(
        None, description="Required when action is SCHEDULE"
    )


class BatchRescheduleRequest(BaseModel):
    items: list[RescheduleItem] = Field(..., min_length=1)


class BatchRescheduleResponse(BaseModel):
    processed_count: int
    updated_tasks: list[TaskRead]


class ReviewSummaryRead(BaseModel):
    date: str
    completed_tasks: list[TaskRead]
    incomplete_tasks: list[TaskRead]
    completed_count: int
    incomplete_count: int
    overdue_count: int
    completion_rate: float
    total_completed_minutes: int
