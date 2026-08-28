from fastapi.testclient import TestClient

from app.core.config import settings
from main import app

client = TestClient(app)


def test_app_version_endpoint():
    """Verify that /api/v1/system/app-version returns valid OTA update metadata (ENH-006 / TS-008)."""
    response = client.get("/api/v1/system/app-version")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "data" in data

    payload = data["data"]
    assert "latest_version" in payload
    assert "min_supported_version" in payload
    assert "apk_download_url" in payload
    assert "release_notes" in payload
    assert "force_update" in payload
    assert isinstance(payload["force_update"], bool)
    assert payload["latest_version"] == settings.LATEST_APP_VERSION
