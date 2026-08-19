import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.category import CategoryCreate, CategoryRead, CategoryUpdate
from app.schemas.response import ApiResponse
from app.services.category_service import category_service

router = APIRouter()


@router.get("", response_model=ApiResponse[list[CategoryRead]])
def get_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[list[CategoryRead]]:
    """Fetch all active categories for the authenticated user."""
    categories = category_service.get_categories(db, current_user.id)
    return ApiResponse(
        data=[CategoryRead.model_validate(c) for c in categories],
        message="Categories retrieved successfully.",
    )


@router.post("", response_model=ApiResponse[CategoryRead], status_code=status.HTTP_201_CREATED)
def create_category(
    category_in: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[CategoryRead]:
    """Create a new category for the authenticated user."""
    category = category_service.create_category(db, category_in, current_user.id)
    return ApiResponse(
        data=CategoryRead.model_validate(category),
        message="Category created successfully.",
    )


@router.get("/{category_id}", response_model=ApiResponse[CategoryRead])
def get_category(
    category_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[CategoryRead]:
    """Get single category details."""
    category = category_service.get_category_by_id(db, category_id, current_user.id)
    return ApiResponse(
        data=CategoryRead.model_validate(category),
        message="Category retrieved successfully.",
    )


@router.put("/{category_id}", response_model=ApiResponse[CategoryRead])
def update_category(
    category_id: uuid.UUID,
    category_in: CategoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[CategoryRead]:
    """Update an existing category."""
    category = category_service.update_category(db, category_id, category_in, current_user.id)
    return ApiResponse(
        data=CategoryRead.model_validate(category),
        message="Category updated successfully.",
    )


@router.delete("/{category_id}", response_model=ApiResponse[None])
def delete_category(
    category_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[None]:
    """Soft delete a category."""
    category_service.delete_category(db, category_id, current_user.id)
    return ApiResponse(
        data=None,
        message="Category deleted successfully.",
    )
