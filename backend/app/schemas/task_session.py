import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.schemas.task import TaskRead


class TaskSessionCreate(BaseModel):
    task_id: uuid.UUID
    scheduled_start: datetime
    scheduled_end: datetime

    @model_validator(mode="after")
    def validate_time_window(self) -> "TaskSessionCreate":
        if self.scheduled_end <= self.scheduled_start:
            raise ValueError("scheduled_end must be strictly after scheduled_start.")
        return self


class TaskSessionUpdate(BaseModel):
    scheduled_start: datetime | None = None
    scheduled_end: datetime | None = None

    @model_validator(mode="after")
    def validate_time_window(self) -> "TaskSessionUpdate":
        if self.scheduled_start is not None and self.scheduled_end is not None:
            if self.scheduled_end <= self.scheduled_start:
                raise ValueError("scheduled_end must be strictly after scheduled_start.")
        return self


class TaskSessionRead(BaseModel):
    id: uuid.UUID
    task_id: uuid.UUID
    scheduled_start: datetime
    scheduled_end: datetime
    duration_minutes: int
    formatted_time_range: str
    has_conflict: bool = False
    conflicting_with: list[str] = []
    task: TaskRead | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
