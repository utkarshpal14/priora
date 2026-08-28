from pydantic import BaseModel, EmailStr, Field, field_validator

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


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ForgotPasswordResponseData(BaseModel):
    message: str = "If an account exists with this email, a 6-digit password reset code has been sent."


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp_code: str = Field(min_length=6, max_length=6, description="6-digit reset code")
    new_password: str = Field(min_length=8, max_length=128, description="New strong password")

    @field_validator("new_password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        import re
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters long.")
        if not re.search(r"[A-Z]", v):
            raise ValueError("Password must contain at least one uppercase letter.")
        if not re.search(r"[a-z]", v):
            raise ValueError("Password must contain at least one lowercase letter.")
        if not re.search(r"[0-9]", v):
            raise ValueError("Password must contain at least one numeric digit.")
        return v


class ResetPasswordResponseData(BaseModel):
    message: str = "Your password has been successfully reset. Please log in with your new password."
