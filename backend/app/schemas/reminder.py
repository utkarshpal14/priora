import uuid
from datetime import UTC, datetime
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field, field_serializer


class ReminderStatus(StrEnum):
    SCHEDULED = "SCHEDULED"
    SENT = "SENT"
    CANCELLED = "CANCELLED"


class ReminderBase(BaseModel):
    remind_at: datetime
    notification_id: int | None = None


class ReminderCreate(ReminderBase):
    task_id: uuid.UUID


class ReminderUpdate(BaseModel):
    remind_at: datetime | None = None
    status: ReminderStatus | None = None
    notification_id: int | None = None


class ReminderRead(BaseModel):
    id: uuid.UUID
    task_id: uuid.UUID
    notification_id: int | None = None
    remind_at: datetime
    status: ReminderStatus
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

    @field_serializer("remind_at", "created_at", "updated_at", when_used="json")
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


class ReminderListResponse(BaseModel):
    reminders: list[ReminderRead]
    total: int
