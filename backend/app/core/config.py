from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Priora API"
    ENVIRONMENT: str = "development"
    API_V1_STR: str = "/api/v1"

    # CORS configuration
    CORS_ORIGINS: list[str] | str = [
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:8080",
        "*",
    ]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: str | list[str]) -> list[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, list):
            return v
        return []

    # Database (PostgreSQL / Supabase)
    DATABASE_URL: str = "postgresql+psycopg://postgres:password@localhost:5432/priora"

    # JWT & Security (Milestone 1)
    JWT_SECRET_KEY: str = "priora-dev-super-secret-jwt-key-2026-secure-32b"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15  # 15 minutes (Document 11)
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30  # 30 days (Document 11)

    # Google OAuth
    GOOGLE_CLIENT_ID: str = ""

    # Email Service & OTP Verification (v1.1.3)
    RESEND_API_KEY: str = ""
    BREVO_API_KEY: str = ""
    SMTP_HOST: str = ""
    SMTP_PORT: int = 465
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    EMAILS_FROM_EMAIL: str = "noreply@priora.app"
    EMAILS_FROM_NAME: str = "Priora"
    OTP_EXPIRE_MINUTES: int = 10
    OTP_RESEND_COOLDOWN_SECONDS: int = 60

    # Supabase credentials (for future milestones)
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    SUPABASE_JWT_SECRET: str = ""

    # In-App Update Management (ENH-006 / TS-008)
    LATEST_APP_VERSION: str = "1.1.4"
    MIN_SUPPORTED_APP_VERSION: str = "1.0.0"
    APK_DOWNLOAD_URL: str = "https://github.com/utkarshpal14/priora/releases/download/v1.1.4/priora-v1.1.4-release.apk"
    APP_RELEASE_NOTES: str = "• Fix recurring tasks reminder rescheduling on next occurrence\n• Full reminder cloning across daily/weekly/monthly routines\n• Reliable native Android high-priority alarm notification dispatch"
    FORCE_APP_UPDATE: bool = False

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )


settings = Settings()
