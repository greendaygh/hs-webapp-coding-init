"""FastAPI Depends — auth_service / 현재 사용자 주입.

`request.app.state.auth_service` 는 main.py startup 훅에서 등록한다.
테스트는 `app.dependency_overrides` 로 fake 주입.
"""
from __future__ import annotations

from fastapi import Depends, HTTPException, Request, status

from {{app_module}}.application.auth_service import AuthService
from {{app_module}}.config import Settings, get_settings
from {{app_module}}.domain.user import User


def get_auth_service(request: Request) -> AuthService:
    service = getattr(request.app.state, "auth_service", None)
    if service is None:
        raise RuntimeError(
            "auth_service is not configured. main.py startup 에서 app.state.auth_service 등록 필요."
        )
    return service


async def get_current_user(
    request: Request,
    settings: Settings = Depends(get_settings),
    service: AuthService = Depends(get_auth_service),
) -> User | None:
    sid = request.cookies.get(settings.session_cookie_name)
    return await service.resolve_session(sid)


async def require_user(user: User | None = Depends(get_current_user)) -> User:
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="not authenticated")
    return user
