import uuid

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
from app.models.user import User
from app.repositories.user_repository import user_repository
from app.schemas.auth import (
    AuthResponseData,
    LoginRequest,
    TokenResponse,
)
from app.schemas.user import UserCreate, UserRead


class AuthService:
    """Service layer managing user authentication, password security, and JWT sessions."""

    def register(self, db: Session, user_in: UserCreate) -> AuthResponseData:
        """Register a new user account with email and password."""
        existing_user = user_repository.get_by_email(db, user_in.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email address is already registered.",
            )

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
        saved_user = user_repository.create(db, new_user)

        tokens = self._generate_tokens(saved_user)
        return AuthResponseData(
            user=UserRead.model_validate(saved_user),
            tokens=tokens,
        )

    def login(self, db: Session, login_in: LoginRequest) -> AuthResponseData:
        """Authenticate user with email and password."""
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

        tokens = self._generate_tokens(user)
        return AuthResponseData(
            user=UserRead.model_validate(user),
            tokens=tokens,
        )

    def authenticate_google(self, db: Session, token: str) -> AuthResponseData:
        """Verify Google ID token and return user session."""
        try:
            # Verify ID token with Google's public certs
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
                # Auto-provision user from verified Google profile
                new_user = User(
                    email=email,
                    hashed_password=None,
                    full_name=name,
                    avatar_url=picture,
                    auth_provider="google",
                    is_email_verified=True,
                    is_active=True,
                )
                user = user_repository.create(db, new_user)
            else:
                # Update profile info if present
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
