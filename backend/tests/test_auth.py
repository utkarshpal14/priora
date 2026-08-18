from datetime import UTC, datetime, timedelta

import jwt
from fastapi.testclient import TestClient

from app.core.config import settings


def test_register_user_success(client: TestClient):
    payload = {
        "email": "testuser@priora.app",
        "password": "SecurePassword123!",
        "full_name": "Test User",
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert data["data"]["user"]["email"] == "testuser@priora.app"
    assert data["data"]["user"]["full_name"] == "Test User"
    assert data["data"]["user"]["auth_provider"] == "email"
    assert data["data"]["user"]["is_email_verified"] is False
    assert "access_token" in data["data"]["tokens"]
    assert "refresh_token" in data["data"]["tokens"]
    assert data["data"]["tokens"]["token_type"] == "bearer"


def test_register_duplicate_email(client: TestClient):
    payload = {
        "email": "duplicate@priora.app",
        "password": "SecurePassword123!",
        "full_name": "Original User",
    }
    res1 = client.post("/api/v1/auth/register", json=payload)
    assert res1.status_code == 201

    res2 = client.post("/api/v1/auth/register", json=payload)
    assert res2.status_code == 400
    assert "already registered" in res2.json()["detail"]


def test_login_success(client: TestClient):
    # Register first
    reg_payload = {
        "email": "loginuser@priora.app",
        "password": "CorrectPassword123!",
        "full_name": "Login User",
    }
    client.post("/api/v1/auth/register", json=reg_payload)

    # Login
    login_payload = {
        "email": "loginuser@priora.app",
        "password": "CorrectPassword123!",
    }
    response = client.post("/api/v1/auth/login", json=login_payload)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["user"]["email"] == "loginuser@priora.app"
    assert "access_token" in data["data"]["tokens"]


def test_login_invalid_password(client: TestClient):
    reg_payload = {
        "email": "badpass@priora.app",
        "password": "CorrectPassword123!",
    }
    client.post("/api/v1/auth/register", json=reg_payload)

    login_payload = {
        "email": "badpass@priora.app",
        "password": "WrongPassword123!",
    }
    response = client.post("/api/v1/auth/login", json=login_payload)
    assert response.status_code == 401
    assert "Invalid email or password" in response.json()["detail"]


def test_login_nonexistent_user(client: TestClient):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "nonexistent@priora.app", "password": "AnyPassword123!"},
    )
    assert response.status_code == 401


def test_get_current_user_profile(client: TestClient):
    reg_payload = {
        "email": "profile@priora.app",
        "password": "SecurePassword123!",
        "full_name": "Profile User",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    access_token = reg_res.json()["data"]["tokens"]["access_token"]

    headers = {"Authorization": f"Bearer {access_token}"}
    response = client.get("/api/v1/users/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["email"] == "profile@priora.app"
    assert data["data"]["full_name"] == "Profile User"


def test_refresh_token_flow(client: TestClient):
    reg_payload = {
        "email": "refresh@priora.app",
        "password": "SecurePassword123!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    refresh_token = reg_res.json()["data"]["tokens"]["refresh_token"]

    response = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "access_token" in data["data"]
    assert "refresh_token" in data["data"]


def test_malformed_token_rejected(client: TestClient):
    headers = {"Authorization": "Bearer not.a.valid.jwt.token"}
    response = client.get("/api/v1/users/me", headers=headers)
    assert response.status_code == 401
    assert "Invalid or malformed" in response.json()["detail"]


def test_expired_token_rejected(client: TestClient):
    # Craft explicitly expired token
    expired_payload = {
        "sub": "00000000-0000-0000-0000-000000000000",
        "email": "expired@priora.app",
        "type": "access",
        "exp": datetime.now(UTC) - timedelta(minutes=10),
    }
    expired_token = jwt.encode(
        expired_payload,
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )

    headers = {"Authorization": f"Bearer {expired_token}"}
    response = client.get("/api/v1/users/me", headers=headers)
    assert response.status_code == 401
    assert "expired" in response.json()["detail"].lower()


def test_refresh_token_cannot_access_protected_endpoint(client: TestClient):
    reg_payload = {
        "email": "wrongtype@priora.app",
        "password": "SecurePassword123!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    refresh_token = reg_res.json()["data"]["tokens"]["refresh_token"]

    # Using refresh token as Authorization header on /users/me
    headers = {"Authorization": f"Bearer {refresh_token}"}
    response = client.get("/api/v1/users/me", headers=headers)
    assert response.status_code == 401
    assert "expected access token" in response.json()["detail"]
