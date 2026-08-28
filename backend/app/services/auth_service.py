import hashlib
import logging
import secrets
import string
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from jwt.exceptions import ExpiredSignatureError, InvalidTokenError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.otp_verification import OtpVerification
from app.models.user import User
from app.repositories.user_repository import user_repository
from app.schemas.auth import (
    AuthResponseData,
    LoginRequest,
    RegistrationResponseData,
    ResendOtpResponseData,
    TokenResponse,
    VerifyOtpRequest,
)
from app.schemas.user import UserCreate, UserRead
from app.services.email_service import email_service

logger = logging.getLogger("priora.auth")


class AuthService:
    """Service layer managing user authentication, OTP verification, and JWT sessions."""

    def _hash_otp(self, otp_code: str) -> str:
        """Hash a 6-digit OTP code using SHA-256 with JWT secret key as salt."""
        salted = f"{otp_code}:{settings.JWT_SECRET_KEY}".encode("utf-8")
        return hashlib.sha256(salted).hexdigest()

    def _generate_otp_code(self) -> str:
        """Generate a cryptographically secure 6-digit numeric OTP."""
        return "".join(secrets.choice(string.digits) for _ in range(6))

    def register(self, db: Session, user_in: UserCreate) -> RegistrationResponseData:
        """
        Register a new user account with email and password.
        Creates an unverified user and dispatches a hashed 6-digit verification code.
        Does NOT issue JWT tokens until verified.
        """
        existing_user = user_repository.get_by_email(db, user_in.email)
        if existing_user:
            if existing_user.is_email_verified:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email address is already registered.",
                )
            # If user exists but is unverified, update their details & password
            existing_user.hashed_password = hash_password(user_in.password)
            existing_user.full_name = user_in.full_name
            existing_user.avatar_url = user_in.avatar_url
            db.commit()
            user = existing_user
        else:
            hashed = hash_password(user_in.password)
            new_user = User(
                email=user_in.email,
                hashed_password=hashed,
                full_name=user_in.full_name,
                avatar_url=user_in.avatar_url,
                auth_provider="email",
                is_email_verified=False,
                is_active=True,
            )
            user = user_repository.create(db, new_user)

        # Invalidate any prior unused OTPs for this email
        db.query(OtpVerification).filter(
            OtpVerification.email == user_in.email,
            OtpVerification.purpose == "email_verification",
            OtpVerification.is_used == False,
        ).update({"is_used": True}, synchronize_session=False)

        # Generate fresh 6-digit OTP
        otp_code = self._generate_otp_code()
        otp_hash = self._hash_otp(otp_code)
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)

        otp_record = OtpVerification(
            email=user_in.email,
            otp_hash=otp_hash,
            purpose="email_verification",
            expires_at=expires_at,
            is_used=False,
            attempts=0,
        )
        db.add(otp_record)
        db.commit()

        # Send email with verification code
        email_service.send_verification_otp(user_in.email, otp_code, user_in.full_name)

        return RegistrationResponseData(
            email=user_in.email,
            is_email_verified=False,
            message="A 6-digit verification code has been sent to your email.",
        )

    def verify_otp(self, db: Session, req: VerifyOtpRequest) -> AuthResponseData:
        """
        Verify the 6-digit OTP code against the hashed record.
        On success: sets user.is_email_verified = True and returns full JWT tokens.
        """
        now = datetime.now(timezone.utc)

        # Fetch latest active OTP for this email
        otp_record = (
            db.query(OtpVerification)
            .filter(
                OtpVerification.email == req.email,
                OtpVerification.purpose == "email_verification",
                OtpVerification.is_used == False,
            )
            .order_by(OtpVerification.created_at.desc())
            .first()
        )

        if not otp_record:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No pending verification code found. Please request a new code.",
            )

        # Ensure not expired
        record_expiry = otp_record.expires_at
        if record_expiry.tzinfo is None:
            record_expiry = record_expiry.replace(tzinfo=timezone.utc)

        if record_expiry < now:
            otp_record.is_used = True
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Verification code has expired. Please request a new code.",
            )

        # Check brute-force attempts limit (max 5)
        if otp_record.attempts >= 5:
            otp_record.is_used = True
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Too many incorrect attempts. This code is invalidated. Please request a new code.",
            )

        # Compare hashed OTP
        provided_hash = self._hash_otp(req.otp_code)
        if otp_record.otp_hash != provided_hash:
            otp_record.attempts += 1
            remaining = 5 - otp_record.attempts
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid verification code. {remaining} attempts remaining.",
            )

        # Verification successful!
        otp_record.is_used = True

        user = user_repository.get_by_email(db, req.email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User account not found.",
            )

        user.is_email_verified = True
        db.commit()

        tokens = self._generate_tokens(user)
        return AuthResponseData(
            user=UserRead.model_validate(user),
            tokens=tokens,
        )

    def resend_otp(self, db: Session, email: str) -> ResendOtpResponseData:
        """
        Resend a new 6-digit OTP code enforcing rate-limiting cooldown.
        """
        user = user_repository.get_by_email(db, email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No account found with this email address.",
            )

        if user.is_email_verified:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This email address is already verified. Please sign in.",
            )

        now = datetime.now(timezone.utc)

        # Check rate-limit cooldown against latest OTP request
        latest_otp = (
            db.query(OtpVerification)
            .filter(
                OtpVerification.email == email,
                OtpVerification.purpose == "email_verification",
            )
            .order_by(OtpVerification.created_at.desc())
            .first()
        )

        if latest_otp:
            created_at = latest_otp.created_at
            if created_at.tzinfo is None:
                created_at = created_at.replace(tzinfo=timezone.utc)
            elapsed = (now - created_at).total_seconds()
            if elapsed < settings.OTP_RESEND_COOLDOWN_SECONDS:
                remaining = int(settings.OTP_RESEND_COOLDOWN_SECONDS - elapsed)
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=f"Please wait {remaining} seconds before requesting a new code.",
                )

        # Invalidate previous codes
        db.query(OtpVerification).filter(
            OtpVerification.email == email,
            OtpVerification.purpose == "email_verification",
            OtpVerification.is_used == False,
        ).update({"is_used": True}, synchronize_session=False)

        # Generate fresh OTP
        otp_code = self._generate_otp_code()
        otp_hash = self._hash_otp(otp_code)
        expires_at = now + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)

        otp_record = OtpVerification(
            email=email,
            otp_hash=otp_hash,
            purpose="email_verification",
            expires_at=expires_at,
            is_used=False,
            attempts=0,
        )
        db.add(otp_record)
        db.commit()

        email_service.send_verification_otp(email, otp_code, user.full_name)

        return ResendOtpResponseData(
            email=email,
            cooldown_seconds=settings.OTP_RESEND_COOLDOWN_SECONDS,
            message="A new verification code has been sent to your email.",
        )

    def login(self, db: Session, login_in: LoginRequest) -> AuthResponseData:
        """Authenticate user with email and password. Rejects unverified accounts."""
        user = user_repository.get_by_email(db, login_in.email)
        if not user or not user.hashed_password:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password.",
            )

        if not verify_password(login_in.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password.",
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="This user account has been deactivated.",
            )

        # Strict Gate: Unverified accounts cannot log in
        if not user.is_email_verified:
            # Auto-send fresh verification OTP
            try:
                self.resend_otp(db, user.email)
            except Exception:
                pass
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Email is not verified. A verification code has been sent to your email.",
            )

        tokens = self._generate_tokens(user)
        return AuthResponseData(
            user=UserRead.model_validate(user),
            tokens=tokens,
        )

    def authenticate_google(self, db: Session, token: str) -> AuthResponseData:
        """Verify Google ID token and return user session."""
        try:
            request = google_requests.Request()
            audience = settings.GOOGLE_CLIENT_ID if settings.GOOGLE_CLIENT_ID else None
            id_info = google_id_token.verify_oauth2_token(token, request, audience)

            email = id_info.get("email")
            if not email:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Google token missing email claim.",
                )

            name = id_info.get("name")
            picture = id_info.get("picture")

            user = user_repository.get_by_email(db, email)
            if not user:
                new_user = User(
                    email=email,
                    hashed_password=None,
                    full_name=name,
                    avatar_url=picture,
                    auth_provider="google",
                    is_email_verified=True,  # Google accounts are pre-verified
                    is_active=True,
                )
                user = user_repository.create(db, new_user)
            else:
                update_data = {}
                if name and not user.full_name:
                    update_data["full_name"] = name
                if picture and not user.avatar_url:
                    update_data["avatar_url"] = picture
                if not user.is_email_verified:
                    update_data["is_email_verified"] = True
                if update_data:
                    user = user_repository.update(db, user, update_data)

            if not user.is_active:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="This user account has been deactivated.",
                )

            tokens = self._generate_tokens(user)
            return AuthResponseData(
                user=UserRead.model_validate(user),
                tokens=tokens,
            )
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid Google ID token: {e!s}",
            ) from e

    def refresh_token(self, db: Session, refresh_token: str) -> TokenResponse:
        """Validate a refresh token and issue new token pair."""
        try:
            payload = decode_token(refresh_token)
            if payload.get("type") != "refresh":
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token type for refresh endpoint.",
                )

            user_id_str = payload.get("sub")
            if not user_id_str:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token payload missing subject identifier.",
                )

            user = user_repository.get_by_id(db, uuid.UUID(user_id_str))
            if not user or not user.is_active:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User account no longer exists or is deactivated.",
                )

            return self._generate_tokens(user)
        except ExpiredSignatureError as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token has expired. Please sign in again.",
            ) from e
        except (InvalidTokenError, ValueError) as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or malformed refresh token.",
            ) from e

    def cleanup_abandoned_accounts(self, db: Session) -> int:
        """Purge unverified accounts older than 24 hours."""
        cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
        deleted = (
            db.query(User)
            .filter(
                User.is_email_verified == False,
                User.created_at < cutoff,
            )
            .delete(synchronize_session=False)
        )
        db.commit()
        logger.info(f"Cleaned up {deleted} abandoned unverified accounts.")
        return deleted

    def migrate_existing_users(self, db: Session) -> int:
        """Mark existing active accounts as email verified to protect current beta testers."""
        updated = (
            db.query(User)
            .filter(
                (User.is_email_verified == False) | (User.is_email_verified.is_(None)),
            )
            .update({"is_email_verified": True}, synchronize_session=False)
        )
        db.commit()
        if updated > 0:
            logger.info(f"Migrated {updated} existing users to is_email_verified=True.")
        return updated

    def _generate_tokens(self, user: User) -> TokenResponse:
        """Generate Access and Refresh tokens for a given user."""
        access_token = create_access_token(subject=str(user.id), email=user.email)
        refresh_token = create_refresh_token(subject=str(user.id), email=user.email)
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in_minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES,
        )


auth_service = AuthService()
