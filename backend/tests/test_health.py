from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Priora API"
    assert data["status"] == "online"
    assert "/api/v1/docs" in data["docs"]


def test_health_check_endpoint():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Priora API is healthy and operational"
    assert "data" in data
    assert data["data"]["status"] == "healthy"
    assert data["data"]["project"] == "Priora API"
    assert data["data"]["api_version"] == "v1.0.0"
