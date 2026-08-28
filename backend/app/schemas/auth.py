from pydantic import BaseModel, EmailStr, Field

from app.schemas.user import UserRead


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1)


class GoogleLoginRequest(BaseModel):
    id_token: str = Field(description="Google OAuth ID Token from client")


class TokenRefreshRequest(BaseModel):
    refresh_token: str = Field(description="Valid long-lived refresh token")


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in_minutes: int = 15


class AuthResponseData(BaseModel):
    user: UserRead
    tokens: TokenResponse


class RegistrationResponseData(BaseModel):
    email: EmailStr
    is_email_verified: bool = False
    message: str = "A 6-digit verification code has been sent to your email."


class VerifyOtpRequest(BaseModel):
    email: EmailStr
    otp_code: str = Field(min_length=6, max_length=6, description="6-digit verification code")


class ResendOtpRequest(BaseModel):
    email: EmailStr


class ResendOtpResponseData(BaseModel):
    email: EmailStr
    cooldown_seconds: int = 60
    message: str = "A new verification code has been sent to your email."
