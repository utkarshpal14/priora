import uuid

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.response import ApiResponse
from app.schemas.task import TaskCreate, TaskListResponse, TaskRead, TaskUpdate
from app.services.task_service import task_service

router = APIRouter()


@router.get("", response_model=ApiResponse[TaskListResponse])
def get_tasks(
    status: str | None = Query(None, description="Filter by status: PENDING, COMPLETED, etc."),
    priority: str | None = Query(
        None, description="Filter by priority: LOW, MEDIUM, HIGH, CRITICAL"
    ),
    category_id: uuid.UUID | None = Query(None, description="Filter by category UUID"),
    search: str | None = Query(None, description="Search term across title and description"),
    limit: int = Query(100, ge=1, le=500, description="Max tasks to return"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[TaskListResponse]:
    """Fetch user tasks with priority ordering, filtering, and summary metrics."""
    result = task_service.get_tasks(
        db=db,
        user_id=current_user.id,
        status_filter=status,
        priority_filter=priority,
        category_id=category_id,
        search=search,
        limit=limit,
    )
    return ApiResponse(
        data=result,
        message="Tasks retrieved successfully.",
    )


@router.post("", response_model=ApiResponse[TaskRead], status_code=status.HTTP_201_CREATED)
def create_task(
    task_in: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[TaskRead]:
    """Create a new task with due date validation."""
    task = task_service.create_task(db, task_in, current_user.id)
    return ApiResponse(
        data=TaskRead.model_validate(task),
        message="Task created successfully.",
    )


@router.get("/{task_id}", response_model=ApiResponse[TaskRead])
def get_task(
    task_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[TaskRead]:
    """Fetch single task details."""
    task = task_service.get_task_by_id(db, task_id, current_user.id)
    return ApiResponse(
        data=TaskRead.model_validate(task),
        message="Task retrieved successfully.",
    )


@router.put("/{task_id}", response_model=ApiResponse[TaskRead])
def update_task(
    task_id: uuid.UUID,
    task_in: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[TaskRead]:
    """Update task properties."""
    task = task_service.update_task(db, task_id, task_in, current_user.id)
    return ApiResponse(
        data=TaskRead.model_validate(task),
        message="Task updated successfully.",
    )


@router.patch("/{task_id}/complete", response_model=ApiResponse[TaskRead])
def complete_task(
    task_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[TaskRead]:
    """Complete a task."""
    task = task_service.complete_task(db, task_id, current_user.id)
    return ApiResponse(
        data=TaskRead.model_validate(task),
        message="Task completed successfully.",
    )


@router.patch("/{task_id}/reopen", response_model=ApiResponse[TaskRead])
def reopen_task(
    task_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[TaskRead]:
    """Reopen a completed task."""
    task = task_service.reopen_task(db, task_id, current_user.id)
    return ApiResponse(
        data=TaskRead.model_validate(task),
        message="Task reopened successfully.",
    )


@router.delete("/{task_id}", response_model=ApiResponse[None])
def delete_task(
    task_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[None]:
    """Soft delete a task."""
    task_service.delete_task(db, task_id, current_user.id)
    return ApiResponse(
        data=None,
        message="Task deleted successfully.",
    )
