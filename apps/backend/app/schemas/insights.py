from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel


class InsightMetrics(BaseModel):
    feeding_count: int
    total_volume_ml: int | None
    total_breast_minutes: int | None
    sleep_total_minutes: int
    diaper_wet_count: int
    diaper_dirty_count: int


class InsightResponse(BaseModel):
    id: UUID
    type: str
    summary_date: date
    content: str
    metrics: InsightMetrics
    created_at: datetime
