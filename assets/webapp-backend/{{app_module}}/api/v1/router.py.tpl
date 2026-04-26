"""API v1 router. 도메인별 sub-router를 여기에 등록한다."""
from fastapi import APIRouter

from {{app_module}}.api.v1.auth import router as auth_router

api_router = APIRouter()
api_router.include_router(auth_router)


@api_router.get("/")
async def index() -> dict[str, str]:
    return {"name": "api", "version": "v1"}
