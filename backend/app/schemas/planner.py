import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.schemas.task import TaskRead
from app.schemas.task_session import TaskSessionRead


class DayPlanSummary(BaseModel):
    total: int = 0
    completed: int = 0
    pending: int = 0
    overdue_count: int = 0
    completion_percentage: float = 0.0
    total_estimated_minutes: int = 0


class TimelineBucket(BaseModel):
    name: str  # Morning, Afternoon, Evening, Anytime
    time_range: str  # e.g., "Before 12:00 PM", "12:00 PM - 5:00 PM", "After 5:00 PM", "Flexible"
    tasks: list[TaskRead] = []


class DailyPlanRead(BaseModel):
    date: str  # YYYY-MM-DD
    summary: DayPlanSummary
    overdue_tasks: list[TaskRead] = []
    focus_tasks: list[TaskRead] = []
    time_blocks: list[TaskSessionRead] = []
    unscheduled_tasks: list[TaskRead] = []
    timeline: list[TimelineBucket] = []

    model_config = ConfigDict(from_attributes=True)


class WeeklyPlanDay(BaseModel):
    date: str  # YYYY-MM-DD
    day_name: str  # e.g., "Monday"
    task_count: int = 0
    due_count: int = 0
    completed_count: int = 0
    overdue_count: int = 0
    has_critical: bool = False


class WeeklyPlanRead(BaseModel):
    start_date: str  # YYYY-MM-DD
    end_date: str  # YYYY-MM-DD
    days: list[WeeklyPlanDay] = []
    total_tasks: int = 0
    completed_tasks: int = 0

    model_config = ConfigDict(from_attributes=True)


class ScheduleTaskRequest(BaseModel):
    task_id: uuid.UUID
    deadline: datetime | None = None


class MoveToTodayRequest(BaseModel):
    task_id: uuid.UUID
