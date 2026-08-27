from fastapi import APIRouter

from app.core.config import settings
from app.schemas.response import ApiResponse
from app.schemas.system import AppVersionResponse

router = APIRouter()


@router.get(
    "/app-version",
    response_model=ApiResponse[AppVersionResponse],
    summary="Get latest application release version metadata",
    description="Public endpoint providing version check and OTA APK download metadata (ENH-006 / TS-008).",
)
def get_app_version() -> ApiResponse[AppVersionResponse]:
    """Returns the latest public app release version, download URL, changelog, and force update flag."""
    payload = AppVersionResponse(
        latest_version=settings.LATEST_APP_VERSION,
        min_supported_version=settings.MIN_SUPPORTED_APP_VERSION,
        apk_download_url=settings.APK_DOWNLOAD_URL,
        release_notes=settings.APP_RELEASE_NOTES,
        force_update=settings.FORCE_APP_UPDATE,
    )
    return ApiResponse(
        success=True,
        message="Application version metadata retrieved successfully.",
        data=payload,
    )
