from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.device_token import DeviceToken
from app.models.user import User
from app.repositories.user_repository import user_repository
from app.schemas.response import ApiResponse
from app.schemas.user import DeviceTokenRegister, NotificationPreferencesUpdate, UserRead, UserUpdate

router = APIRouter()


@router.get(
    "/me",
    response_model=ApiResponse[UserRead],
    summary="Get current user profile",
)
def get_me(
    current_user: User = Depends(get_current_user),
) -> ApiResponse[UserRead]:
    """Retrieve profile data for the authenticated user."""
    return ApiResponse(
        success=True,
        message="Profile retrieved successfully.",
        data=UserRead.model_validate(current_user),
    )


@router.put(
    "/me",
    response_model=ApiResponse[UserRead],
    summary="Update current user profile",
)
def update_me(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ApiResponse[UserRead]:
    """Update profile information (e.g. full name, avatar, settings) for current user."""
    update_data = user_update.model_dump(exclude_unset=True)
    updated_user = user_repository.update(db, current_user, update_data)
    return ApiResponse(
        success=True,
        message="Profile updated successfully.",
        data=UserRead.model_validate(updated_user),
    )


@router.get(
    "/notification-preferences",
    response_model=ApiResponse[NotificationPreferencesUpdate],
    summary="Get user notification preferences",
)
def get_notification_preferences(
    current_user: User = Depends(get_current_user),
) -> ApiResponse[NotificationPreferencesUpdate]:
    """Get current user notification preferences."""
    prefs = NotificationPreferencesUpdate(
        notifications_enabled=current_user.notifications_enabled,
        sound_enabled=current_user.sound_enabled,
        deadline_reminders=current_user.deadline_reminders,
        review_reminders=current_user.review_reminders,
        goal_alerts=current_user.goal_alerts,
    )
    return ApiResponse(
        success=True,
        message="Notification preferences retrieved.",
        data=prefs,
    )


@router.put(
    "/notification-preferences",
    response_model=ApiResponse[NotificationPreferencesUpdate],
    summary="Update user notification preferences",
)
def update_notification_preferences(
    prefs_update: NotificationPreferencesUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ApiResponse[NotificationPreferencesUpdate]:
    """Update notification preferences for current user."""
    update_data = prefs_update.model_dump()
    updated_user = user_repository.update(db, current_user, update_data)
    prefs = NotificationPreferencesUpdate(
        notifications_enabled=updated_user.notifications_enabled,
        sound_enabled=updated_user.sound_enabled,
        deadline_reminders=updated_user.deadline_reminders,
        review_reminders=updated_user.review_reminders,
        goal_alerts=updated_user.goal_alerts,
    )
    return ApiResponse(
        success=True,
        message="Notification preferences updated successfully.",
        data=prefs,
    )


@router.post(
    "/device-token",
    response_model=ApiResponse[dict],
    summary="Register push device token",
    status_code=status.HTTP_201_CREATED,
)
def register_device_token(
    payload: DeviceTokenRegister,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ApiResponse[dict]:
    """Register FCM/APNs push notification token for user device."""
    existing = db.query(DeviceToken).filter(DeviceToken.token == payload.token).first()
    if existing:
        existing.user_id = current_user.id
        existing.platform = payload.platform
    else:
        dev_token = DeviceToken(
            user_id=current_user.id,
            token=payload.token,
            platform=payload.platform,
        )
        db.add(dev_token)
    db.commit()
    return ApiResponse(
        success=True,
        message="Device token registered successfully.",
        data={"token": payload.token, "platform": payload.platform},
    )


@router.delete(
    "/device-token/{token}",
    response_model=ApiResponse[dict],
    summary="Unregister push device token",
)
def unregister_device_token(
    token: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ApiResponse[dict]:
    """Unregister FCM/APNs device token on logout or disable."""
    dev_token = db.query(DeviceToken).filter(
        DeviceToken.token == token,
        DeviceToken.user_id == current_user.id,
    ).first()
    if dev_token:
        db.delete(dev_token)
        db.commit()
    return ApiResponse(
        success=True,
        message="Device token unregistered successfully.",
        data={"token": token},
    )
