from fastapi import APIRouter, Depends, HTTPException, Request, status
from supabase_auth.errors import AuthApiError
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.database import get_supabase
from app.dependencies import get_current_user_id
from app.schemas.auth import AuthResponse, LoginRequest, RefreshRequest, SignUpRequest, TokenResponse

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)


@router.post("/signup", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("3/minute")
async def signup(request: Request, body: SignUpRequest):
    supabase = get_supabase()
    try:
        result = supabase.auth.sign_up({"email": body.email, "password": body.password})
    except AuthApiError as exc:
        msg = str(exc).lower()
        if "already registered" in msg or "already exists" in msg:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))

    if result.user is None or result.session is None:
        # Supabase project has email confirmation enabled — disable it in Auth settings for Phase 1
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email confirmation is enabled on this Supabase project. Disable it under Auth > Settings.",
        )

    # Upsert profile row (safe to call even if a race created it first)
    supabase.table("profiles").upsert({
        "id": result.user.id,
        "email": body.email,
    }).execute()

    return AuthResponse(
        user_id=result.user.id,
        access_token=result.session.access_token,
        refresh_token=result.session.refresh_token,
    )


@router.post("/login", response_model=AuthResponse)
@limiter.limit("5/minute")
async def login(request: Request, body: LoginRequest):
    supabase = get_supabase()
    try:
        result = supabase.auth.sign_in_with_password({"email": body.email, "password": body.password})
    except AuthApiError:
        # Never reveal whether the email exists
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    return AuthResponse(
        user_id=result.user.id,
        access_token=result.session.access_token,
        refresh_token=result.session.refresh_token,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest):
    supabase = get_supabase()
    try:
        result = supabase.auth.refresh_session(body.refresh_token)
    except AuthApiError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token")

    return TokenResponse(
        access_token=result.session.access_token,
        refresh_token=result.session.refresh_token,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(user_id: str = Depends(get_current_user_id)):
    # JWT is already validated by the dependency. The client discards tokens from
    # secure storage. Server-side session invalidation requires passing the raw
    # JWT to supabase.auth.admin — deferred to SEC-003.
    return None
