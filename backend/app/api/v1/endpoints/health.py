from datetime import UTC, datetime
from typing import Any

from fastapi import APIRouter

from app.core.config import settings
from app.schemas.response import ApiResponse

router = APIRouter()


@router.get(
    "/health",
    response_model=ApiResponse[dict[str, Any]],
    summary="Health check endpoint",
    description="Check the operational status of the Priora API",
)
def health_check() -> ApiResponse[dict[str, Any]]:
    """Returns the API health status and basic environment metadata."""
    payload = {
        "status": "healthy",
        "project": settings.PROJECT_NAME,
        "environment": settings.ENVIRONMENT,
        "api_version": "v1.0.0",
        "timestamp": datetime.now(UTC).isoformat(),
    }
    return ApiResponse(
        success=True,
        message="Priora API is healthy and operational",
        data=payload,
    )
