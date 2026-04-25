"""API v1 router. 도메인별 sub-router를 여기에 등록한다."""
from fastapi import APIRouter

api_router = APIRouter()


@api_router.get("/")
async def index() -> dict[str, str]:
    return {"name": "api", "version": "v1"}
