from pydantic import BaseModel, Field


class AppVersionResponse(BaseModel):
    """Schema representing application version and OTA update metadata (ENH-006 / TS-008)."""
    latest_version: str = Field(..., description="Latest available public release version")
    min_supported_version: str = Field(..., description="Minimum supported client version")
    apk_download_url: str = Field(..., description="Direct download URL for the latest release APK")
    release_notes: str = Field(..., description="Formatted changelog or release highlights")
    force_update: bool = Field(default=False, description="Whether update is strictly required")
