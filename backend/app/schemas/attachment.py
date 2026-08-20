import re
import uuid
from datetime import UTC, datetime
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field, computed_field, field_serializer, field_validator


class AttachmentType(StrEnum):
    IMAGE = "IMAGE"
    DOCUMENT = "DOCUMENT"
    LINK = "LINK"
    NOTE = "NOTE"


class AttachmentSourceType(StrEnum):
    UPLOAD = "UPLOAD"
    LINK = "LINK"
    NOTE = "NOTE"


def validate_entity_exclusivity(task_id: uuid.UUID | None, goal_id: uuid.UUID | None, milestone_id: uuid.UUID | None) -> None:
    entity_count = sum(1 for e in (task_id, goal_id, milestone_id) if e is not None)
    if entity_count != 1:
        raise ValueError("Exactly one target entity (task_id, goal_id, or milestone_id) must be provided.")


class AttachmentCreateLink(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    url: str = Field(..., min_length=1, max_length=1000)
    task_id: uuid.UUID | None = None
    goal_id: uuid.UUID | None = None
    milestone_id: uuid.UUID | None = None
    tags: str | None = Field(default=None, max_length=500)
    is_pinned: bool = False

    @field_validator("url")
    @classmethod
    def validate_url(cls, v: str) -> str:
        v_stripped = v.strip()
        if not re.match(r"^https?://", v_stripped, re.IGNORECASE):
            raise ValueError("URL must start with http:// or https://")
        return v_stripped

    @field_validator("milestone_id")
    @classmethod
    def validate_entities(cls, v: uuid.UUID | None, info) -> uuid.UUID | None:
        data = info.data
        validate_entity_exclusivity(data.get("task_id"), data.get("goal_id"), v)
        return v


class AttachmentCreateNote(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    content: str = Field(..., min_length=1)
    task_id: uuid.UUID | None = None
    goal_id: uuid.UUID | None = None
    milestone_id: uuid.UUID | None = None
    tags: str | None = Field(default=None, max_length=500)
    is_pinned: bool = False

    @field_validator("milestone_id")
    @classmethod
    def validate_entities(cls, v: uuid.UUID | None, info) -> uuid.UUID | None:
        data = info.data
        validate_entity_exclusivity(data.get("task_id"), data.get("goal_id"), v)
        return v


class AttachmentRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    task_id: uuid.UUID | None = None
    goal_id: uuid.UUID | None = None
    milestone_id: uuid.UUID | None = None
    type: str
    source_type: str
    name: str
    original_filename: str | None = None
    url: str | None = None
    thumbnail_url: str | None = None
    domain: str | None = None
    site_name: str | None = None
    favicon_url: str | None = None
    content: str | None = None
    tags: str | None = None
    file_hash: str | None = None
    mime_type: str | None = None
    file_size_bytes: int | None = None
    is_pinned: bool = False
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

    @field_serializer("created_at", "updated_at", when_used="json")
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
    def formatted_size(self) -> str | None:
        if self.file_size_bytes is None:
            return None
        bytes_val = self.file_size_bytes
        if bytes_val < 1024:
            return f"{bytes_val} B"
        elif bytes_val < 1024 * 1024:
            return f"{bytes_val / 1024:.1f} KB"
        else:
            return f"{bytes_val / (1024 * 1024):.1f} MB"


class AttachmentListResponse(BaseModel):
    attachments: list[AttachmentRead]
    total: int
    storage_used_bytes: int
