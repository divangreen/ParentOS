from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, field_validator


class ChildCreate(BaseModel):
    name: str
    date_of_birth: date
    birth_weight_kg: float | None = None

    @field_validator("name")
    @classmethod
    def name_length(cls, v: str) -> str:
        v = v.strip()
        if not 1 <= len(v) <= 100:
            raise ValueError("Name must be 1–100 characters")
        return v

    @field_validator("date_of_birth")
    @classmethod
    def dob_valid(cls, v: date) -> date:
        today = date.today()
        if v > today:
            raise ValueError("Date of birth cannot be in the future")
        if (today - v).days > 366:
            raise ValueError("Date of birth cannot be more than 366 days ago")
        return v

    @field_validator("birth_weight_kg")
    @classmethod
    def weight_range(cls, v: float | None) -> float | None:
        if v is not None and not 0.5 <= v <= 6.0:
            raise ValueError("Birth weight must be between 0.5 and 6.0 kg")
        return v


class ChildUpdate(BaseModel):
    name: str | None = None
    date_of_birth: date | None = None
    birth_weight_kg: float | None = None


class ChildResponse(BaseModel):
    id: UUID
    name: str
    date_of_birth: date
    birth_weight_kg: float | None
    age_days: int
    created_at: datetime


class ChildListResponse(BaseModel):
    children: list[ChildResponse]
