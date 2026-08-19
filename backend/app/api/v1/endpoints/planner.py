from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.planner import DailyPlanRead, MoveToTodayRequest, ScheduleTaskRequest, WeeklyPlanRead
from app.schemas.response import ApiResponse
from app.schemas.task import TaskRead
from app.services.planner_service import planner_service

router = APIRouter()


@router.get(
    "/day",
    response_model=ApiResponse[DailyPlanRead],
    summary="Get daily plan",
    description="Fetch today's or target date's daily timeline, progress summary, and top 3 smart focus tasks.",
)
def get_daily_plan(
    date: Annotated[str | None, Query(description="Target date in YYYY-MM-DD format")] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[DailyPlanRead]:
    daily_plan = planner_service.get_daily_plan(db, current_user.id, date)
    return ApiResponse(
        success=True,
        message="Daily plan retrieved successfully.",
        data=daily_plan,
    )


@router.get(
    "/week",
    response_model=ApiResponse[WeeklyPlanRead],
    summary="Get weekly overview",
    description="Fetch 7-day schedule overview with task counts, due counts, and completion statuses.",
)
def get_weekly_plan(
    start_date: Annotated[str | None, Query(description="Week start date in YYYY-MM-DD format")] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[WeeklyPlanRead]:
    weekly_plan = planner_service.get_weekly_plan(db, current_user.id, start_date)
    return ApiResponse(
        success=True,
        message="Weekly plan retrieved successfully.",
        data=weekly_plan,
    )


@router.post(
    "/move-to-today",
    response_model=ApiResponse[TaskRead],
    summary="Move task to today",
    description="Quick action to reschedule any task to today's schedule.",
)
def move_task_to_today(
    payload: MoveToTodayRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[TaskRead]:
    task = planner_service.move_task_to_today(db, current_user.id, payload.task_id)
    return ApiResponse(
        success=True,
        message="Task moved to today successfully.",
        data=task,
    )


@router.post(
    "/schedule",
    response_model=ApiResponse[TaskRead],
    summary="Schedule or plan task",
    description="Update a task's planned deadline date and time.",
)
def schedule_task(
    payload: ScheduleTaskRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[TaskRead]:
    task = planner_service.schedule_task(db, current_user.id, payload.task_id, payload.deadline)
    return ApiResponse(
        success=True,
        message="Task scheduled successfully.",
        data=task,
    )
