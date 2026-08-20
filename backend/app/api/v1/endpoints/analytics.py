from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.analytics import (
    AnalyticsBreakdownRead,
    AnalyticsHeatmapRead,
    AnalyticsOverviewRead,
    WeeklyAnalyticsRead,
)
from app.schemas.response import ApiResponse
from app.services.analytics_service import analytics_service

router = APIRouter()


@router.get("/overview", response_model=ApiResponse[AnalyticsOverviewRead])
def get_analytics_overview(
    days: int = Query(30, ge=1, le=365, description="Number of historical days to analyze"),
    tz_offset: int = Query(0, description="Timezone offset in minutes"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[AnalyticsOverviewRead]:
    """Get high-level productivity overview, streaks, personal records, goal stats, and focus time."""
    data = analytics_service.get_overview(db, current_user.id, days=days, tz_offset=tz_offset)
    return ApiResponse(data=data, message="Analytics overview retrieved successfully.")


@router.get("/weekly", response_model=ApiResponse[WeeklyAnalyticsRead])
def get_weekly_analytics(
    days: int = Query(7, ge=1, le=60, description="Number of days for velocity chart"),
    tz_offset: int = Query(0, description="Timezone offset in minutes"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[WeeklyAnalyticsRead]:
    """Get completion velocity, completion rate trend %, and time-of-day execution breakdown."""
    data = analytics_service.get_weekly(db, current_user.id, days=days, tz_offset=tz_offset)
    return ApiResponse(data=data, message="Weekly analytics retrieved successfully.")


@router.get("/breakdown", response_model=ApiResponse[AnalyticsBreakdownRead])
def get_analytics_breakdown(
    days: int = Query(30, ge=1, le=365, description="Number of days to analyze"),
    tz_offset: int = Query(0, description="Timezone offset in minutes"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[AnalyticsBreakdownRead]:
    """Get category distribution and priority breakdown for completed tasks."""
    data = analytics_service.get_breakdown(db, current_user.id, days=days, tz_offset=tz_offset)
    return ApiResponse(data=data, message="Category and priority breakdown retrieved successfully.")


@router.get("/heatmap", response_model=ApiResponse[AnalyticsHeatmapRead])
def get_analytics_heatmap(
    days: int = Query(30, ge=7, le=365, description="Number of days for activity heatmap"),
    tz_offset: int = Query(0, description="Timezone offset in minutes"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ApiResponse[AnalyticsHeatmapRead]:
    """Get GitHub-style 30-day activity contribution heatmap dataset."""
    data = analytics_service.get_heatmap(db, current_user.id, days=days, tz_offset=tz_offset)
    return ApiResponse(data=data, message="Activity heatmap retrieved successfully.")
