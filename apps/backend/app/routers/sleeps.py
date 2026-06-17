from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.access import assert_child_owned
from app.database import get_supabase
from app.dates import day_bounds, utc_today
from app.dependencies import get_current_user_id
from app.schemas.sleeps import SleepCreate, SleepListResponse, SleepResponse

router = APIRouter()


@router.post("/{child_id}/sleeps", response_model=SleepResponse, status_code=status.HTTP_201_CREATED)
async def create_sleep(
    child_id: UUID,
    body: SleepCreate,
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    assert_child_owned(supabase, child_id, user_id)

    result = (
        supabase.table("sleeps")
        .insert(
            {
                "child_id": str(child_id),
                "user_id": user_id,
                "type": body.type,
                "started_at": body.started_at.isoformat(),
                "ended_at": body.ended_at.isoformat(),
            }
        )
        .execute()
    )
    return SleepResponse(**result.data[0])


@router.get("/{child_id}/sleeps", response_model=SleepListResponse)
async def list_sleeps(
    child_id: UUID,
    date: date = Query(default_factory=utc_today),
    limit: int = Query(default=50, le=200),
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    assert_child_owned(supabase, child_id, user_id)

    start, end = day_bounds(date)
    result = (
        supabase.table("sleeps")
        .select("*")
        .eq("child_id", str(child_id))
        .gte("started_at", start)
        .lt("started_at", end)
        .order("started_at", desc=True)
        .limit(limit)
        .execute()
    )
    sleeps = [SleepResponse(**row) for row in result.data]
    total_minutes_today = sum(s.duration_minutes for s in sleeps)
    return SleepListResponse(sleeps=sleeps, total_minutes_today=total_minutes_today)


@router.delete("/{child_id}/sleeps/{sleep_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_sleep(
    child_id: UUID,
    sleep_id: UUID,
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    assert_child_owned(supabase, child_id, user_id)

    result = (
        supabase.table("sleeps")
        .delete()
        .eq("id", str(sleep_id))
        .eq("child_id", str(child_id))
        .eq("user_id", user_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sleep not found")
