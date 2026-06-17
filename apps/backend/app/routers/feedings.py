from datetime import date, datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.access import assert_child_owned
from app.database import get_supabase
from app.dates import day_bounds, utc_today
from app.dependencies import get_current_user_id
from app.schemas.feedings import FeedingCreate, FeedingListResponse, FeedingResponse

router = APIRouter()


@router.post("/{child_id}/feedings", response_model=FeedingResponse, status_code=status.HTTP_201_CREATED)
async def create_feeding(
    child_id: UUID,
    body: FeedingCreate,
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    assert_child_owned(supabase, child_id, user_id)

    logged_at = body.logged_at or datetime.now(timezone.utc)
    result = (
        supabase.table("feedings")
        .insert(
            {
                "child_id": str(child_id),
                "user_id": user_id,
                "type": body.type,
                "side": body.side,
                "duration_minutes": body.duration_minutes,
                "volume_ml": body.volume_ml,
                "milk_type": body.milk_type,
                "logged_at": logged_at.isoformat(),
            }
        )
        .execute()
    )
    return FeedingResponse(**result.data[0])


@router.get("/{child_id}/feedings", response_model=FeedingListResponse)
async def list_feedings(
    child_id: UUID,
    date: date = Query(default_factory=utc_today),
    limit: int = Query(default=50, le=200),
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    assert_child_owned(supabase, child_id, user_id)

    start, end = day_bounds(date)
    result = (
        supabase.table("feedings")
        .select("*")
        .eq("child_id", str(child_id))
        .gte("logged_at", start)
        .lt("logged_at", end)
        .order("logged_at", desc=True)
        .limit(limit)
        .execute()
    )
    feedings = [FeedingResponse(**row) for row in result.data]
    return FeedingListResponse(feedings=feedings, total=len(feedings))


@router.delete("/{child_id}/feedings/{feeding_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_feeding(
    child_id: UUID,
    feeding_id: UUID,
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    assert_child_owned(supabase, child_id, user_id)

    result = (
        supabase.table("feedings")
        .delete()
        .eq("id", str(feeding_id))
        .eq("child_id", str(child_id))
        .eq("user_id", user_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Feeding not found")
