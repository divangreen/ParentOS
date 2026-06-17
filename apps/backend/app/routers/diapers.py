from datetime import date, datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.access import assert_child_owned
from app.database import get_supabase
from app.dates import day_bounds, utc_today
from app.dependencies import get_current_user_id
from app.schemas.diapers import DiaperCreate, DiaperListResponse, DiaperResponse

router = APIRouter()


@router.post("/{child_id}/diapers", response_model=DiaperResponse, status_code=status.HTTP_201_CREATED)
async def create_diaper(
    child_id: UUID,
    body: DiaperCreate,
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    assert_child_owned(supabase, child_id, user_id)

    logged_at = body.logged_at or datetime.now(timezone.utc)
    result = (
        supabase.table("diapers")
        .insert(
            {
                "child_id": str(child_id),
                "user_id": user_id,
                "type": body.type,
                "logged_at": logged_at.isoformat(),
            }
        )
        .execute()
    )
    return DiaperResponse(**result.data[0])


@router.get("/{child_id}/diapers", response_model=DiaperListResponse)
async def list_diapers(
    child_id: UUID,
    date: date = Query(default_factory=utc_today),
    limit: int = Query(default=50, le=200),
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    assert_child_owned(supabase, child_id, user_id)

    start, end = day_bounds(date)
    result = (
        supabase.table("diapers")
        .select("*")
        .eq("child_id", str(child_id))
        .gte("logged_at", start)
        .lt("logged_at", end)
        .order("logged_at", desc=True)
        .limit(limit)
        .execute()
    )
    diapers = [DiaperResponse(**row) for row in result.data]
    wet_count = sum(1 for d in diapers if d.type in ("wet", "both"))
    dirty_count = sum(1 for d in diapers if d.type in ("dirty", "both"))
    return DiaperListResponse(diapers=diapers, wet_count=wet_count, dirty_count=dirty_count)


@router.delete("/{child_id}/diapers/{diaper_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_diaper(
    child_id: UUID,
    diaper_id: UUID,
    user_id: str = Depends(get_current_user_id),
):
    supabase = get_supabase()
    assert_child_owned(supabase, child_id, user_id)

    result = (
        supabase.table("diapers")
        .delete()
        .eq("id", str(diaper_id))
        .eq("child_id", str(child_id))
        .eq("user_id", user_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Diaper not found")
