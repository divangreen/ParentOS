from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.database import get_supabase
from app.dependencies import get_current_user_id
from app.schemas.children import ChildCreate, ChildListResponse, ChildResponse, ChildUpdate

router = APIRouter()


def _to_response(row: dict) -> ChildResponse:
    dob = date.fromisoformat(row["date_of_birth"])
    return ChildResponse(
        id=row["id"],
        name=row["name"],
        date_of_birth=dob,
        birth_weight_kg=row["birth_weight_kg"],
        age_days=(date.today() - dob).days,
        created_at=row["created_at"],
    )


def _get_owned_child(supabase, child_id: UUID, user_id: str) -> dict:
    result = (
        supabase.table("children")
        .select("*")
        .eq("id", str(child_id))
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child not found")
    return result.data[0]


@router.post("", response_model=ChildResponse, status_code=status.HTTP_201_CREATED)
async def create_child(body: ChildCreate, user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    result = (
        supabase.table("children")
        .insert(
            {
                "user_id": user_id,
                "name": body.name,
                "date_of_birth": body.date_of_birth.isoformat(),
                "birth_weight_kg": body.birth_weight_kg,
            }
        )
        .execute()
    )
    return _to_response(result.data[0])


@router.get("", response_model=ChildListResponse)
async def list_children(user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    result = (
        supabase.table("children")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=False)
        .execute()
    )
    return ChildListResponse(children=[_to_response(row) for row in result.data])


@router.get("/{child_id}", response_model=ChildResponse)
async def get_child(child_id: UUID, user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    row = _get_owned_child(supabase, child_id, user_id)
    return _to_response(row)


@router.patch("/{child_id}", response_model=ChildResponse)
async def update_child(child_id: UUID, body: ChildUpdate, user_id: str = Depends(get_current_user_id)):
    supabase = get_supabase()
    _get_owned_child(supabase, child_id, user_id)

    updates = body.model_dump(exclude_unset=True)
    if "date_of_birth" in updates and updates["date_of_birth"] is not None:
        updates["date_of_birth"] = updates["date_of_birth"].isoformat()
    if not updates:
        row = _get_owned_child(supabase, child_id, user_id)
        return _to_response(row)

    result = (
        supabase.table("children")
        .update(updates)
        .eq("id", str(child_id))
        .eq("user_id", user_id)
        .execute()
    )
    return _to_response(result.data[0])
