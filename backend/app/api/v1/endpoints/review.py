from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.response import ApiResponse
from app.schemas.review import (
    BatchRescheduleRequest,
    BatchRescheduleResponse,
    ReviewSummaryRead,
)
from app.services.review_service import review_service

router = APIRouter()


@router.get(
    "/daily",
    response_model=ApiResponse[ReviewSummaryRead],
    summary="Get daily review summary",
    description="Fetch today's completed accomplishments and unfinished rollover tasks for daily review.",
)
def get_daily_review(
    date: Annotated[str | None, Query(description="Target date in YYYY-MM-DD format")] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[ReviewSummaryRead]:
    summary = review_service.get_daily_review(db, current_user.id, date)
    return ApiResponse(
        success=True,
        message="Daily review retrieved successfully.",
        data=summary,
    )


@router.post(
    "/batch-reschedule",
    response_model=ApiResponse[BatchRescheduleResponse],
    summary="Batch reschedule incomplete tasks",
    description="Apply atomic resolution actions (Move Tomorrow, Move Next Week, Schedule, Complete, Cancel) to rollover tasks.",
)
def batch_reschedule(
    payload: BatchRescheduleRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[BatchRescheduleResponse]:
    result = review_service.batch_reschedule(db, current_user.id, payload.items)
    return ApiResponse(
        success=True,
        message="Tasks rescheduled successfully.",
        data=result,
    )
