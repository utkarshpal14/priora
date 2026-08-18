from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.auth import (
    AuthResponseData,
    GoogleLoginRequest,
    LoginRequest,
    TokenRefreshRequest,
    TokenResponse,
)
from app.schemas.response import ApiResponse
from app.schemas.user import UserCreate
from app.services.auth_service import auth_service

router = APIRouter()


@router.post(
    "/register",
    response_model=ApiResponse[AuthResponseData],
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user account",
)
def register(
    user_in: UserCreate,
    db: Session = Depends(get_db),
) -> ApiResponse[AuthResponseData]:
    """Register a new email/password account."""
    auth_data = auth_service.register(db, user_in)
    return ApiResponse(
        success=True,
        message="Account registered successfully.",
        data=auth_data,
    )


@router.post(
    "/login",
    response_model=ApiResponse[AuthResponseData],
    summary="Sign in with email and password",
)
def login(
    login_in: LoginRequest,
    db: Session = Depends(get_db),
) -> ApiResponse[AuthResponseData]:
    """Authenticate with email and password."""
    auth_data = auth_service.login(db, login_in)
    return ApiResponse(
        success=True,
        message="Signed in successfully.",
        data=auth_data,
    )


@router.post(
    "/google",
    response_model=ApiResponse[AuthResponseData],
    summary="Sign in or register with Google OAuth ID token",
)
def login_google(
    request_in: GoogleLoginRequest,
    db: Session = Depends(get_db),
) -> ApiResponse[AuthResponseData]:
    """Verify Google OAuth token and issue Priora session tokens."""
    auth_data = auth_service.authenticate_google(db, request_in.id_token)
    return ApiResponse(
        success=True,
        message="Google sign in successful.",
        data=auth_data,
    )


@router.post(
    "/refresh",
    response_model=ApiResponse[TokenResponse],
    summary="Refresh access token",
)
def refresh_token(
    refresh_in: TokenRefreshRequest,
    db: Session = Depends(get_db),
) -> ApiResponse[TokenResponse]:
    """Exchange a valid refresh token for a fresh token pair."""
    token_data = auth_service.refresh_token(db, refresh_in.refresh_token)
    return ApiResponse(
        success=True,
        message="Token refreshed successfully.",
        data=token_data,
    )


@router.post(
    "/logout",
    response_model=ApiResponse[None],
    summary="Sign out user session",
)
def logout() -> ApiResponse[None]:
    """Client invalidates locally stored tokens on logout."""
    return ApiResponse(
        success=True,
        message="Logged out successfully.",
        data=None,
    )
