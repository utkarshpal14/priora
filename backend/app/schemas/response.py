from typing import Any

from pydantic import BaseModel, Field


class ApiResponse[T](BaseModel):
    """Standard success response envelope across all Priora APIs."""
    success: bool = Field(default=True, description="Indicates whether request was successful")
    message: str = Field(default="Success", description="Human-readable response message")
    data: T | None = Field(default=None, description="Response payload")


class ErrorResponse(BaseModel):
    """Standard error response envelope across all Priora APIs."""
    success: bool = Field(default=False, description="Indicates request failure")
    message: str = Field(..., description="High-level error description")
    errors: list[Any] = Field(
        default_factory=list,
        description="Detailed validation or execution errors",
    )
