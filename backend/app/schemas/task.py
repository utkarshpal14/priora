import uuid
from datetime import UTC, datetime
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field, computed_field, field_serializer

from app.schemas.category import CategoryRead


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
    deadline: datetime | None = None


class TaskCreate(TaskBase):
    pass


class TaskUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = None
    priority: TaskPriority | None = None
    status: TaskStatus | None = None
    category_id: uuid.UUID | None = None
    deadline: datetime | None = None


class TaskRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    description: str | None = None
    priority: TaskPriority
    status: TaskStatus
    category_id: uuid.UUID | None = None
    category: CategoryRead | None = None
    deadline: datetime | None = None
    completed_at: datetime | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

    @field_serializer("deadline", "completed_at", "created_at", "updated_at", when_used="json")
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

