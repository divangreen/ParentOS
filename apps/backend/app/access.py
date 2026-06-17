from uuid import UUID

from fastapi import HTTPException, status


def assert_child_owned(supabase, child_id: UUID, user_id: str) -> None:
    """Raises 404 if the child doesn't exist or isn't owned by user_id."""
    result = (
        supabase.table("children")
        .select("id")
        .eq("id", str(child_id))
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Child not found")
