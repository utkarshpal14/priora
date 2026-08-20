import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserBase(BaseModel):
    email: EmailStr
    full_name: str | None = None
    avatar_url: str | None = None


class UserCreate(UserBase):
    password: str = Field(min_length=8, description="Plaintext user password (min 8 chars)")


class UserUpdate(BaseModel):
    full_name: str | None = None
    avatar_url: str | None = None
    notifications_enabled: bool | None = None
    sound_enabled: bool | None = None
    deadline_reminders: bool | None = None
    review_reminders: bool | None = None
    goal_alerts: bool | None = None


class NotificationPreferencesUpdate(BaseModel):
    notifications_enabled: bool = True
    sound_enabled: bool = True
    deadline_reminders: bool = True
    review_reminders: bool = True
    goal_alerts: bool = True


class DeviceTokenRegister(BaseModel):
    token: str = Field(min_length=1, description="Push notification token (FCM/APNs)")
    platform: str = Field(default="android", description="Device platform (android, ios, web)")


class UserRead(UserBase):
    id: uuid.UUID
    auth_provider: str
    is_email_verified: bool
    is_active: bool
    storage_used_bytes: int = 0
    notifications_enabled: bool = True
    sound_enabled: bool = True
    deadline_reminders: bool = True
    review_reminders: bool = True
    goal_alerts: bool = True
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
