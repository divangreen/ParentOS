import time

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.config import settings
from app.routers import auth, children, diapers, feedings, insights, sleeps

limiter = Limiter(key_func=get_remote_address)

app = FastAPI(
    title="ParentOS API",
    version="0.1.0",
    docs_url="/docs" if settings.debug else None,
    redoc_url=None,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    # Local dev tools (flutter run -d chrome, python -m http.server, etc.) use
    # arbitrary ports -- allow any localhost/127.0.0.1 origin regardless of port,
    # in addition to the explicit production origins in allow_origins above.
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    ms = round((time.time() - start) * 1000)
    ip = get_remote_address(request)
    user_id = getattr(request.state, "user_id", "-")
    print(
        f"ip={ip} method={request.method} path={request.url.path} "
        f"status={response.status_code} ms={ms} user={user_id}"
    )
    return response


app.include_router(auth.router, prefix="/v1/auth", tags=["auth"])
app.include_router(children.router, prefix="/v1/children", tags=["children"])
app.include_router(feedings.router, prefix="/v1/children", tags=["feedings"])
app.include_router(sleeps.router, prefix="/v1/children", tags=["sleeps"])
app.include_router(diapers.router, prefix="/v1/children", tags=["diapers"])
app.include_router(insights.router, prefix="/v1/children", tags=["insights"])


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok", "version": "0.1.0"}
