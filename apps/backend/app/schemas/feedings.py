from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, model_validator


class FeedingCreate(BaseModel):
    type: Literal["breast", "bottle"]
    side: Literal["left", "right", "both"] | None = None
    duration_minutes: int | None = None
    volume_ml: int | None = None
    milk_type: Literal["breast_milk", "formula"] | None = None
    logged_at: datetime | None = None

    @model_validator(mode="after")
    def validate_by_type(self) -> "FeedingCreate":
        if self.type == "breast":
            if self.side is None:
                raise ValueError("side is required for breast feeds")
            if self.duration_minutes is None:
                raise ValueError("duration_minutes is required for breast feeds")
            if not 1 <= self.duration_minutes <= 120:
                raise ValueError("duration_minutes must be 1–120")
        if self.type == "bottle":
            if self.volume_ml is None:
                raise ValueError("volume_ml is required for bottle feeds")
            if not 10 <= self.volume_ml <= 500:
                raise ValueError("volume_ml must be 10–500")
        return self


class FeedingResponse(BaseModel):
    id: UUID
    type: str
    side: str | None
    duration_minutes: int | None
    volume_ml: int | None
    milk_type: str | None
    logged_at: datetime
    created_at: datetime


class FeedingListResponse(BaseModel):
    feedings: list[FeedingResponse]
    total: int
