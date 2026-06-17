from fastapi import Request
from fastapi.responses import JSONResponse


def error_response(error: str, message: str, field: str | None = None, status_code: int = 400) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={"error": error, "message": message, "field": field},
    )


async def not_found_handler(request: Request, exc: Exception) -> JSONResponse:
    return JSONResponse(status_code=404, content={"error": "not_found", "message": "Resource not found", "field": None})
