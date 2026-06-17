from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, model_validator


class SleepCreate(BaseModel):
    type: Literal["nap", "night"]
    started_at: datetime
    ended_at: datetime

    @model_validator(mode="after")
    def validate_times(self) -> "SleepCreate":
        if self.ended_at <= self.started_at:
            raise ValueError("ended_at must be after started_at")
        duration = (self.ended_at - self.started_at).total_seconds() / 60
        if not 1 <= duration <= 1440:
            raise ValueError("Sleep duration must be between 1 minute and 24 hours")
        return self


class SleepResponse(BaseModel):
    id: UUID
    type: str
    started_at: datetime
    ended_at: datetime
    duration_minutes: int
    created_at: datetime


class SleepListResponse(BaseModel):
    sleeps: list[SleepResponse]
    total_minutes_today: int
