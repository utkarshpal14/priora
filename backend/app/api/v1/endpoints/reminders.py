import uuid
from typing import Any

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.reminder import (
    ReminderCreate,
    ReminderListResponse,
    ReminderRead,
    ReminderUpdate,
)
from app.services.reminder_service import reminder_service

router = APIRouter()


@router.post("", status_code=status.HTTP_201_CREATED, response_model=dict[str, Any])
def create_reminder(
    reminder_in: ReminderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    """Create a new task reminder."""
    reminder = reminder_service.create_reminder(
        db=db,
        reminder_in=reminder_in,
        user_id=current_user.id,
    )
    return {
        "status": "success",
        "data": ReminderRead.model_validate(reminder),
    }


@router.get("", response_model=dict[str, Any])
def get_reminders(
    task_id: uuid.UUID | None = Query(default=None),
    status: str | None = Query(default=None),
    limit: int = Query(default=100, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    """Get all reminders for the authenticated user."""
    reminders = reminder_service.get_user_reminders(
        db=db,
        user_id=current_user.id,
        task_id=task_id,
        status_filter=status,
        limit=limit,
    )
    return {
        "status": "success",
        "data": ReminderListResponse(
            reminders=[ReminderRead.model_validate(r) for r in reminders],
            total=len(reminders),
        ),
    }


@router.get("/{id}", response_model=dict[str, Any])
def get_reminder(
    id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    """Get a specific reminder by ID."""
    reminder = reminder_service.get_reminder_by_id(
        db=db,
        reminder_id=id,
        user_id=current_user.id,
    )
    return {
        "status": "success",
        "data": ReminderRead.model_validate(reminder),
    }


@router.put("/{id}", response_model=dict[str, Any])
def update_reminder(
    id: uuid.UUID,
    reminder_in: ReminderUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    """Update a reminder's time, status, or notification ID."""
    reminder = reminder_service.update_reminder(
        db=db,
        reminder_id=id,
        reminder_in=reminder_in,
        user_id=current_user.id,
    )
    return {
        "status": "success",
        "data": ReminderRead.model_validate(reminder),
    }


@router.delete("/{id}", response_model=dict[str, Any])
def delete_reminder(
    id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    """Soft delete / cancel a reminder."""
    reminder_service.delete_reminder(
        db=db,
        reminder_id=id,
        user_id=current_user.id,
    )
    return {
        "status": "success",
        "message": "Reminder deleted successfully.",
    }
