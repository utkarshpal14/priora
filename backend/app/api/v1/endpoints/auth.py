from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.auth import (
    AuthResponseData,
    ForgotPasswordRequest,
    ForgotPasswordResponseData,
    GoogleLoginRequest,
    LoginRequest,
    RegistrationResponseData,
    ResendOtpRequest,
    ResendOtpResponseData,
    ResetPasswordRequest,
    ResetPasswordResponseData,
    TokenRefreshRequest,
    TokenResponse,
    VerifyOtpRequest,
)
from app.schemas.response import ApiResponse
from app.schemas.user import UserCreate
from app.services.auth_service import auth_service

router = APIRouter()


@router.post(
    "/register",
    response_model=ApiResponse[RegistrationResponseData],
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user account and send 6-digit OTP",
)
def register(
    user_in: UserCreate,
    db: Session = Depends(get_db),
) -> ApiResponse[RegistrationResponseData]:
    """Register a new email/password account and dispatch a verification OTP."""
    auth_data = auth_service.register(db, user_in)
    return ApiResponse(
        success=True,
        message="Account registered. Please verify your email with the 6-digit code.",
        data=auth_data,
    )


@router.post(
    "/verify-otp",
    response_model=ApiResponse[AuthResponseData],
    summary="Verify 6-digit email OTP and activate account",
)
def verify_otp(
    req: VerifyOtpRequest,
    db: Session = Depends(get_db),
) -> ApiResponse[AuthResponseData]:
    """Verify 6-digit OTP, activate email verification, and issue initial session tokens."""
    auth_data = auth_service.verify_otp(db, req)
    return ApiResponse(
        success=True,
        message="Email verified successfully. Welcome to Priora!",
        data=auth_data,
    )


@router.post(
    "/resend-otp",
    response_model=ApiResponse[ResendOtpResponseData],
    summary="Resend 6-digit verification OTP (subject to 60s cooldown)",
)
def resend_otp(
    req: ResendOtpRequest,
    db: Session = Depends(get_db),
) -> ApiResponse[ResendOtpResponseData]:
    """Resend a new 6-digit OTP to the registered email."""
    resend_data = auth_service.resend_otp(db, req.email)
    return ApiResponse(
        success=True,
        message="A new verification code has been sent to your email.",
        data=resend_data,
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
    """Authenticate with email and password (requires email verification)."""
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
    "/forgot-password",
    response_model=ApiResponse[ForgotPasswordResponseData],
    summary="Request a 6-digit password reset OTP",
)
def forgot_password(
    req: ForgotPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> ApiResponse[ForgotPasswordResponseData]:
    """Request a password reset code. Timing-safe & enumeration-resistant."""
    client_ip = request.client.host if request.client else None
    result = auth_service.forgot_password(db, req, client_ip=client_ip)
    return ApiResponse(
        success=True,
        message=result.message,
        data=result,
    )


@router.post(
    "/reset-password",
    response_model=ApiResponse[ResetPasswordResponseData],
    summary="Reset password using 6-digit OTP and revoke all existing sessions",
)
def reset_password(
    req: ResetPasswordRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> ApiResponse[ResetPasswordResponseData]:
    """Verify 6-digit reset code, update password, and revoke previous sessions."""
    client_ip = request.client.host if request.client else None
    result = auth_service.reset_password(db, req, client_ip=client_ip)
    return ApiResponse(
        success=True,
        message=result.message,
        data=result,
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
