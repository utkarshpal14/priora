from datetime import UTC, datetime, timedelta

import jwt
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.otp_verification import OtpVerification
from app.models.user import User


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
    assert data["data"]["email"] == "testuser@priora.app"
    assert data["data"]["is_email_verified"] is False
    assert "verification code" in data["data"]["message"].lower()


def test_verify_otp_success_and_login(client: TestClient, db_session: Session):
    email = "otpuser@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "SecurePassword123!", "full_name": "OTP User"},
    )

    # Fetch active OTP record and compute valid code
    # We can inspect the OTP verification record
    from app.services.auth_service import auth_service

    # Generate known code
    test_otp = "123456"
    test_hash = auth_service._hash_otp(test_otp)
    db_session.query(OtpVerification).filter(OtpVerification.email == email).update({"otp_hash": test_hash})
    db_session.commit()

    # Verify OTP
    verify_res = client.post("/api/v1/auth/verify-otp", json={"email": email, "otp_code": test_otp})
    assert verify_res.status_code == 200
    verify_data = verify_res.json()
    assert verify_data["success"] is True
    assert verify_data["data"]["user"]["email"] == email
    assert verify_data["data"]["user"]["is_email_verified"] is True
    assert "access_token" in verify_data["data"]["tokens"]

    # Now login succeeds
    login_res = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "SecurePassword123!"},
    )
    assert login_res.status_code == 200
    assert login_res.json()["data"]["user"]["is_email_verified"] is True


def test_login_unverified_rejected(client: TestClient):
    email = "unverified@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "SecurePassword123!", "full_name": "Unverified User"},
    )

    # Login without verifying OTP should return 403 Forbidden
    login_res = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "SecurePassword123!"},
    )
    assert login_res.status_code == 403
    assert "not verified" in login_res.json()["detail"].lower()


def test_verify_otp_invalid_code(client: TestClient):
    email = "wrongcode@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "SecurePassword123!"},
    )

    verify_res = client.post(
        "/api/v1/auth/verify-otp",
        json={"email": email, "otp_code": "000000"},
    )
    assert verify_res.status_code == 400
    assert "invalid" in verify_res.json()["detail"].lower()


def test_resend_otp_rate_limit_cooldown(client: TestClient):
    email = "resenduser@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "SecurePassword123!"},
    )

    # Immediate resend should trigger 429 Too Many Requests
    resend_res = client.post("/api/v1/auth/resend-otp", json={"email": email})
    assert resend_res.status_code == 429
    assert "wait" in resend_res.json()["detail"].lower()


def test_register_duplicate_verified_email(client: TestClient, db_session: Session):
    email = "duplicate@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "SecurePassword123!", "full_name": "Original User"},
    )

    # Mark verified
    db_session.query(User).filter(User.email == email).update({"is_email_verified": True})
    db_session.commit()

    # Attempting to register again
    res2 = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "SecurePassword123!", "full_name": "Original User"},
    )
    assert res2.status_code == 400
    assert "already registered" in res2.json()["detail"]


def test_get_current_user_profile(client: TestClient, db_session: Session):
    email = "profile@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "SecurePassword123!", "full_name": "Profile User"},
    )

    from app.services.auth_service import auth_service
    test_otp = "888888"
    db_session.query(OtpVerification).filter(OtpVerification.email == email).update({"otp_hash": auth_service._hash_otp(test_otp)})
    db_session.commit()

    verify_res = client.post("/api/v1/auth/verify-otp", json={"email": email, "otp_code": test_otp})
    access_token = verify_res.json()["data"]["tokens"]["access_token"]

    headers = {"Authorization": f"Bearer {access_token}"}
    response = client.get("/api/v1/users/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["email"] == email
    assert data["data"]["full_name"] == "Profile User"


def test_refresh_token_flow(client: TestClient, db_session: Session):
    email = "refresh@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "SecurePassword123!"},
    )

    from app.services.auth_service import auth_service
    test_otp = "999999"
    db_session.query(OtpVerification).filter(OtpVerification.email == email).update({"otp_hash": auth_service._hash_otp(test_otp)})
    db_session.commit()

    verify_res = client.post("/api/v1/auth/verify-otp", json={"email": email, "otp_code": test_otp})
    refresh_token = verify_res.json()["data"]["tokens"]["refresh_token"]

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
