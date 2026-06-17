from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel


class DiaperCreate(BaseModel):
    type: Literal["wet", "dirty", "both"]
    logged_at: datetime | None = None


class DiaperResponse(BaseModel):
    id: UUID
    type: str
    logged_at: datetime
    created_at: datetime


class DiaperListResponse(BaseModel):
    diapers: list[DiaperResponse]
    wet_count: int
    dirty_count: int
