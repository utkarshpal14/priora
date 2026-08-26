import uuid
from datetime import UTC, datetime
from enum import StrEnum
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, computed_field, field_serializer, field_validator

from app.schemas.category import CategoryRead
from app.schemas.reminder import ReminderRead, ReminderStatus


class TaskPriority(StrEnum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"


class TaskStatus(StrEnum):
    PENDING = "PENDING"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class TaskBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: str | None = None
    priority: TaskPriority = TaskPriority.MEDIUM
    category_id: uuid.UUID | None = None
    goal_id: uuid.UUID | None = None
    milestone_id: uuid.UUID | None = None
    deadline: datetime | None = None
    scheduled_start: datetime | None = None
    scheduled_end: datetime | None = None
    estimated_minutes: int | None = Field(default=None, ge=1, le=1440)
    repeat_type: str = "none"  # none, daily, weekly, monthly
    repeat_interval: int = Field(default=1, ge=1, le=365)
    repeat_end_date: datetime | None = None


class TaskCreate(TaskBase):
    pass


class TaskUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = None
    priority: TaskPriority | None = None
    status: TaskStatus | None = None
    category_id: uuid.UUID | None = None
    goal_id: uuid.UUID | None = None
    milestone_id: uuid.UUID | None = None
    deadline: datetime | None = None
    scheduled_start: datetime | None = None
    scheduled_end: datetime | None = None
    estimated_minutes: int | None = Field(default=None, ge=1, le=1440)
    repeat_type: str | None = None
    repeat_interval: int | None = Field(default=None, ge=1, le=365)
    repeat_end_date: datetime | None = None


class TaskRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    description: str | None = None
    priority: TaskPriority
    status: TaskStatus
    category_id: uuid.UUID | None = None
    category: CategoryRead | None = None
    goal_id: uuid.UUID | None = None
    milestone_id: uuid.UUID | None = None
    deadline: datetime | None = None
    scheduled_start: datetime | None = None
    scheduled_end: datetime | None = None
    estimated_minutes: int | None = None
    repeat_type: str = "none"
    repeat_interval: int = 1
    repeat_end_date: datetime | None = None
    attachment_count: int = Field(default=0)
    completed_at: datetime | None = None
    created_at: datetime
    updated_at: datetime
    reminders: list[ReminderRead] = []

    model_config = ConfigDict(from_attributes=True)

    @field_validator("attachment_count", mode="before")
    @classmethod
    def default_attachment_count(cls, v: Any) -> int:
        if v is None:
            return 0
        try:
            return int(v)
        except (ValueError, TypeError):
            return 0

    @field_serializer(
        "deadline",
        "scheduled_start",
        "scheduled_end",
        "repeat_end_date",
        "completed_at",
        "created_at",
        "updated_at",
        when_used="json",
    )
    def serialize_datetime_utc(self, dt: datetime | None) -> str | None:
        if dt is None:
            return None
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=UTC)
        else:
            dt = dt.astimezone(UTC)
        iso = dt.isoformat()
        if iso.endswith("+00:00"):
            iso = iso[:-6] + "Z"
        elif not iso.endswith("Z") and "+" not in iso:
            iso += "Z"
        return iso

    @computed_field
    @property
    def has_active_reminder(self) -> bool:
        return any(r.status == ReminderStatus.SCHEDULED for r in self.reminders)

    @computed_field
    @property
    def is_overdue(self) -> bool:
        if self.status in (TaskStatus.COMPLETED, TaskStatus.CANCELLED):
            return False
        if self.deadline is None:
            return False
        deadline_utc = self.deadline if self.deadline.tzinfo else self.deadline.replace(tzinfo=UTC)
        return deadline_utc < datetime.now(UTC)

    @computed_field
    @property
    def is_due_today(self) -> bool:
        if self.status in (TaskStatus.COMPLETED, TaskStatus.CANCELLED):
            return False
        if self.deadline is None:
            return False
        deadline_utc = self.deadline if self.deadline.tzinfo else self.deadline.replace(tzinfo=UTC)
        now_utc = datetime.now(UTC)
        start_of_day = datetime(now_utc.year, now_utc.month, now_utc.day, 0, 0, 0, tzinfo=UTC)
        end_of_day = datetime(now_utc.year, now_utc.month, now_utc.day, 23, 59, 59, 999999, tzinfo=UTC)
        return start_of_day <= deadline_utc <= end_of_day


class TaskMetrics(BaseModel):
    total: int = 0
    completed: int = 0
    pending: int = 0
    overdue: int = 0
    due_today: int = 0


class TaskListResponse(BaseModel):
    tasks: list[TaskRead]
    metrics: TaskMetrics

