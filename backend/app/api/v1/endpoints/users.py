from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.repositories.user_repository import user_repository
from app.schemas.response import ApiResponse
from app.schemas.user import UserRead, UserUpdate

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
    """Update profile information (e.g. full name, avatar) for current user."""
    update_data = user_update.model_dump(exclude_unset=True)
    updated_user = user_repository.update(db, current_user, update_data)
    return ApiResponse(
        success=True,
        message="Profile updated successfully.",
        data=UserRead.model_validate(updated_user),
    )
