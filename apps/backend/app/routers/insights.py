from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import get_current_user_id
from app.schemas.insights import InsightResponse

router = APIRouter()


@router.post("/{child_id}/insights/generate", response_model=InsightResponse)
async def generate_insight(
    child_id: UUID,
    user_id: str = Depends(get_current_user_id),
):
    # Task AI-005
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Not implemented")


@router.get("/{child_id}/insights/latest", response_model=InsightResponse)
async def get_latest_insight(
    child_id: UUID,
    user_id: str = Depends(get_current_user_id),
):
    # Task AI-006
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Not implemented")
