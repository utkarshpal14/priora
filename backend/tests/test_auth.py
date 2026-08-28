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


def test_forgot_password_valid_user(client: TestClient, db_session: Session):
    email = "forgot_valid@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Password123!", "full_name": "Forgot User"},
    )
    # Mark verified
    db_session.query(User).filter(User.email == email).update({"is_email_verified": True})
    db_session.commit()

    res = client.post("/api/v1/auth/forgot-password", json={"email": email})
    assert res.status_code == 200
    assert res.json()["success"] is True

    # Confirm password_reset OTP is stored
    otp = db_session.query(OtpVerification).filter(
        OtpVerification.email == email,
        OtpVerification.purpose == "password_reset",
        OtpVerification.is_used == False,
    ).first()
    assert otp is not None


def test_forgot_password_nonexistent_user_enumeration_safe(client: TestClient, db_session: Session):
    email = "nonexistent_stranger@priora.app"
    res = client.post("/api/v1/auth/forgot-password", json={"email": email})
    assert res.status_code == 200
    assert res.json()["success"] is True

    # No OTP created
    otp = db_session.query(OtpVerification).filter(OtpVerification.email == email).first()
    assert otp is None


def test_forgot_password_cooldown_rejection(client: TestClient, db_session: Session):
    email = "cooldown_forgot@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Password123!", "full_name": "Cooldown User"},
    )
    db_session.query(User).filter(User.email == email).update({"is_email_verified": True})
    db_session.commit()

    # First request
    client.post("/api/v1/auth/forgot-password", json={"email": email})

    # Immediate second request
    res2 = client.post("/api/v1/auth/forgot-password", json={"email": email})
    assert res2.status_code == 200
    assert "recently sent" in res2.json()["data"]["message"].lower()


def test_reset_password_success_and_login(client: TestClient, db_session: Session):
    from app.services.auth_service import auth_service

    email = "reset_success@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "OldPassword123!", "full_name": "Reset Hero"},
    )
    db_session.query(User).filter(User.email == email).update({"is_email_verified": True})
    db_session.commit()

    # Request reset
    client.post("/api/v1/auth/forgot-password", json={"email": email})

    # Set known OTP
    test_otp = "654321"
    test_hash = auth_service._hash_otp(test_otp)
    db_session.query(OtpVerification).filter(
        OtpVerification.email == email,
        OtpVerification.purpose == "password_reset",
    ).update({"otp_hash": test_hash})
    db_session.commit()

    # Reset password
    res = client.post(
        "/api/v1/auth/reset-password",
        json={"email": email, "otp_code": test_otp, "new_password": "NewStrongPassword999!"},
    )
    assert res.status_code == 200
    assert res.json()["success"] is True

    # Old password fails
    old_login = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "OldPassword123!"},
    )
    assert old_login.status_code == 401

    # New password succeeds
    new_login = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "NewStrongPassword999!"},
    )
    assert new_login.status_code == 200
    assert new_login.json()["success"] is True


def test_reset_password_revokes_existing_jwt_sessions(client: TestClient, db_session: Session):
    from app.services.auth_service import auth_service

    email = "revoke_session@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "OldPassword123!", "full_name": "Revoke User"},
    )
    db_session.query(User).filter(User.email == email).update({"is_email_verified": True})
    db_session.commit()

    # Login and acquire active session tokens
    login_res = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "OldPassword123!"},
    )
    access_token = login_res.json()["data"]["tokens"]["access_token"]
    refresh_token = login_res.json()["data"]["tokens"]["refresh_token"]

    # Verify access token works initially
    headers = {"Authorization": f"Bearer {access_token}"}
    me_res = client.get("/api/v1/users/me", headers=headers)
    assert me_res.status_code == 200

    # Perform password reset
    client.post("/api/v1/auth/forgot-password", json={"email": email})
    test_otp = "112233"
    db_session.query(OtpVerification).filter(
        OtpVerification.email == email,
        OtpVerification.purpose == "password_reset",
    ).update({"otp_hash": auth_service._hash_otp(test_otp)})
    db_session.commit()

    client.post(
        "/api/v1/auth/reset-password",
        json={"email": email, "otp_code": test_otp, "new_password": "NewBrandPassword888!"},
    )

    # Old access token is now REVOKED (token_version mismatch)
    me_revoked = client.get("/api/v1/users/me", headers=headers)
    assert me_revoked.status_code == 401
    assert "revoked" in me_revoked.json()["detail"].lower()

    # Old refresh token is also REVOKED
    refresh_revoked = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_revoked.status_code == 401
    assert "revoked" in refresh_revoked.json()["detail"].lower()


def test_reset_password_expired_otp_rejection(client: TestClient, db_session: Session):
    from app.services.auth_service import auth_service

    email = "expired_reset@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Password123!"},
    )
    db_session.query(User).filter(User.email == email).update({"is_email_verified": True})
    db_session.commit()

    client.post("/api/v1/auth/forgot-password", json={"email": email})

    # Set expired
    test_otp = "777777"
    db_session.query(OtpVerification).filter(
        OtpVerification.email == email,
        OtpVerification.purpose == "password_reset",
    ).update({
        "otp_hash": auth_service._hash_otp(test_otp),
        "expires_at": datetime.now(UTC) - timedelta(minutes=5),
    })
    db_session.commit()

    res = client.post(
        "/api/v1/auth/reset-password",
        json={"email": email, "otp_code": test_otp, "new_password": "NewStrongPassword777!"},
    )
    assert res.status_code == 400
    assert "expired" in res.json()["detail"].lower()


def test_reset_password_reused_otp_rejection(client: TestClient, db_session: Session):
    from app.services.auth_service import auth_service

    email = "reused_reset@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Password123!"},
    )
    db_session.query(User).filter(User.email == email).update({"is_email_verified": True})
    db_session.commit()

    client.post("/api/v1/auth/forgot-password", json={"email": email})
    test_otp = "888111"
    db_session.query(OtpVerification).filter(
        OtpVerification.email == email,
        OtpVerification.purpose == "password_reset",
    ).update({"otp_hash": auth_service._hash_otp(test_otp)})
    db_session.commit()

    # Use once
    res1 = client.post(
        "/api/v1/auth/reset-password",
        json={"email": email, "otp_code": test_otp, "new_password": "NewStrongPassword1!"},
    )
    assert res1.status_code == 200

    # Try reusing same OTP
    res2 = client.post(
        "/api/v1/auth/reset-password",
        json={"email": email, "otp_code": test_otp, "new_password": "AnotherNewPassword2!"},
    )
    assert res2.status_code == 400
    assert "no active" in res2.json()["detail"].lower()


def test_reset_password_bruteforce_lockout_5_attempts(client: TestClient, db_session: Session):
    from app.services.auth_service import auth_service

    email = "bruteforce_reset@priora.app"
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Password123!"},
    )
    db_session.query(User).filter(User.email == email).update({"is_email_verified": True})
    db_session.commit()

    client.post("/api/v1/auth/forgot-password", json={"email": email})
    test_otp = "999000"
    db_session.query(OtpVerification).filter(
        OtpVerification.email == email,
        OtpVerification.purpose == "password_reset",
    ).update({"otp_hash": auth_service._hash_otp(test_otp)})
    db_session.commit()

    # 4 bad attempts
    for _ in range(4):
        bad_res = client.post(
            "/api/v1/auth/reset-password",
            json={"email": email, "otp_code": "000000", "new_password": "NewStrongPassword1!"},
        )
        assert bad_res.status_code == 400

    # 5th bad attempt -> 429 lockout
    lockout_res = client.post(
        "/api/v1/auth/reset-password",
        json={"email": email, "otp_code": "000000", "new_password": "NewStrongPassword1!"},
    )
    assert lockout_res.status_code == 429
    assert "too many failed attempts" in lockout_res.json()["detail"].lower()


def test_reset_password_purpose_isolation(client: TestClient, db_session: Session):
    from app.services.auth_service import auth_service

    email = "isolation@priora.app"
    # Registration creates email_verification OTP
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Password123!"},
    )
    test_otp = "555666"
    db_session.query(OtpVerification).filter(
        OtpVerification.email == email,
        OtpVerification.purpose == "email_verification",
    ).update({"otp_hash": auth_service._hash_otp(test_otp)})
    db_session.commit()

    # Attempting to use email_verification OTP on reset-password endpoint must fail
    res = client.post(
        "/api/v1/auth/reset-password",
        json={"email": email, "otp_code": test_otp, "new_password": "NewStrongPassword1!"},
    )
    assert res.status_code == 400
    assert "no active password reset code" in res.json()["detail"].lower()


def test_reset_password_weak_password_rejected(client: TestClient):
    # Missing uppercase, number, etc.
    res = client.post(
        "/api/v1/auth/reset-password",
        json={"email": "weak@priora.app", "otp_code": "123456", "new_password": "weak"},
    )
    assert res.status_code == 422

