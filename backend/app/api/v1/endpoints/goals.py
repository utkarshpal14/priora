import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.goal import (
    GoalCreate,
    GoalDetailRead,
    GoalListResponse,
    GoalMilestoneCreate,
    GoalMilestoneRead,
    GoalUpdate,
)
from app.schemas.response import ApiResponse
from app.services.goal_service import goal_service

router = APIRouter()


@router.get(
    "",
    response_model=ApiResponse[GoalListResponse],
    summary="List all goals",
    description="Retrieve all active goals with calculated progress percentages and aggregate status metrics.",
)
def list_goals(
    status: Annotated[str | None, Query(description="Filter goals by status (e.g. IN_PROGRESS, COMPLETED)")] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[GoalListResponse]:
    response = goal_service.get_goals(db, current_user.id, status)
    return ApiResponse(
        success=True,
        message="Goals retrieved successfully.",
        data=response,
    )


@router.post(
    "",
    response_model=ApiResponse[GoalDetailRead],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new goal",
    description="Create a goal optionally bundled with initial milestones.",
)
def create_goal(
    goal_in: GoalCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[GoalDetailRead]:
    goal = goal_service.create_goal(db, goal_in, current_user.id)
    return ApiResponse(
        success=True,
        message="Goal created successfully.",
        data=goal,
    )


@router.get(
    "/{goal_id}",
    response_model=ApiResponse[GoalDetailRead],
    summary="Get goal details",
    description="Retrieve goal details, including milestone checklists, linked tasks, and recent completion activity.",
)
def get_goal(
    goal_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[GoalDetailRead]:
    goal = goal_service.get_goal_detail(db, goal_id, current_user.id)
    return ApiResponse(
        success=True,
        message="Goal details retrieved successfully.",
        data=goal,
    )


@router.put(
    "/{goal_id}",
    response_model=ApiResponse[GoalDetailRead],
    summary="Update a goal",
    description="Update goal properties (title, description, target date, category, status, color, icon).",
)
def update_goal(
    goal_id: uuid.UUID,
    goal_in: GoalUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[GoalDetailRead]:
    goal = goal_service.update_goal(db, goal_id, goal_in, current_user.id)
    return ApiResponse(
        success=True,
        message="Goal updated successfully.",
        data=goal,
    )


@router.delete(
    "/{goal_id}",
    response_model=ApiResponse[None],
    summary="Delete a goal",
    description="Soft delete a goal and its associated hierarchy.",
)
def delete_goal(
    goal_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[None]:
    goal_service.delete_goal(db, goal_id, current_user.id)
    return ApiResponse(
        success=True,
        message="Goal deleted successfully.",
        data=None,
    )


# -------------------- Milestone Endpoints --------------------

@router.post(
    "/{goal_id}/milestones",
    response_model=ApiResponse[GoalMilestoneRead],
    status_code=status.HTTP_201_CREATED,
    summary="Add a milestone to goal",
    description="Add a checkpoint milestone with optional description and target date to a goal.",
)
def add_milestone(
    goal_id: uuid.UUID,
    milestone_in: GoalMilestoneCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[GoalMilestoneRead]:
    milestone = goal_service.add_milestone(db, goal_id, milestone_in, current_user.id)
    return ApiResponse(
        success=True,
        message="Milestone added successfully.",
        data=milestone,
    )


@router.patch(
    "/{goal_id}/milestones/{milestone_id}/toggle",
    response_model=ApiResponse[GoalMilestoneRead],
    summary="Toggle milestone completion",
    description="Toggle milestone completed flag and recalculate goal progress.",
)
def toggle_milestone(
    goal_id: uuid.UUID,
    milestone_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[GoalMilestoneRead]:
    milestone = goal_service.toggle_milestone(db, goal_id, milestone_id, current_user.id)
    return ApiResponse(
        success=True,
        message="Milestone status updated.",
        data=milestone,
    )


@router.delete(
    "/{goal_id}/milestones/{milestone_id}",
    response_model=ApiResponse[None],
    summary="Delete a milestone",
    description="Soft delete a milestone from a goal.",
)
def delete_milestone(
    goal_id: uuid.UUID,
    milestone_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[None]:
    goal_service.delete_milestone(db, goal_id, milestone_id, current_user.id)
    return ApiResponse(
        success=True,
        message="Milestone deleted successfully.",
        data=None,
    )
