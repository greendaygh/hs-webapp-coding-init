"""Auth router — OIDC 로그인/콜백/로그아웃/현재 사용자.

- `GET /auth/providers` — 활성 공급자 목록 (프런트의 LoginButton 노출용).
- `GET /auth/login/{provider}` — IdP 로 redirect.
- `GET /auth/callback/{provider}` — 코드 교환 → upsert → 세션 쿠키 발급 → 프런트로 redirect.
- `GET /auth/login/mock?email=...` — dev/test 전용 단축 로그인. settings.oidc_mock_enabled 가 true 일 때만 동작.
- `POST /auth/logout` — 세션 폐기 + 쿠키 제거.
- `GET /auth/me` — 현재 사용자 (없으면 401).

OIDC mock 은 IdP 등록 없이도 흐름을 시연 가능하게 한다. 운영(prod/staging) 에서는
`OIDC_MOCK_ENABLED=true` 자체가 main.py startup 가드에서 차단된다.
"""
from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, Request, Response, status
from fastapi.responses import RedirectResponse

from {{app_module}}.api.dependencies import (
    get_auth_service,
    get_current_user,
    require_user,
)
from {{app_module}}.application.auth_service import AuthService
from {{app_module}}.config import Settings, get_settings
from {{app_module}}.domain.user import User

router = APIRouter(prefix="/auth", tags=["auth"])


def _set_session_cookie(response: Response, name: str, sid: str, ttl_hours: int, secure: bool) -> None:
    response.set_cookie(
        key=name,
        value=sid,
        max_age=ttl_hours * 3600,
        httponly=True,
        samesite="lax",
        secure=secure,
        path="/",
    )


def _clear_session_cookie(response: Response, name: str) -> None:
    response.delete_cookie(key=name, path="/")


@router.get("/providers")
async def list_providers(settings: Settings = Depends(get_settings)) -> dict[str, list[str]]:
    return {"providers": settings.active_oidc_providers}


@router.get("/me")
async def me(user: User = Depends(require_user)) -> dict[str, Any]:
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "provider": user.provider,
        "roles": user.roles,
    }


@router.post("/logout")
async def logout(
    request: Request,
    response: Response,
    settings: Settings = Depends(get_settings),
    service: AuthService = Depends(get_auth_service),
) -> dict[str, bool]:
    sid = request.cookies.get(settings.session_cookie_name)
    await service.revoke_session(sid)
    _clear_session_cookie(response, settings.session_cookie_name)
    return {"ok": True}


@router.get("/login/mock")
async def login_mock(
    email: str = Query(...),
    name: str | None = Query(default=None),
    settings: Settings = Depends(get_settings),
    service: AuthService = Depends(get_auth_service),
) -> RedirectResponse:
    """Dev/test 전용 단축 로그인. prod/staging 에서는 startup 가드가 막는다."""
    if not settings.oidc_mock_enabled:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="mock provider disabled")
    user = await service.upsert_user_from_oidc(
        "mock", {"sub": f"mock-{email}", "email": email, "name": name or email}
    )
    session = await service.create_session(user.id)
    secure = settings.environment in ("staging", "production")
    redirect = RedirectResponse(url=settings.oidc_post_login_redirect, status_code=302)
    _set_session_cookie(redirect, settings.session_cookie_name, session.id, settings.session_ttl_hours, secure)
    return redirect


@router.get("/login/{provider}")
async def login(provider: str, request: Request, settings: Settings = Depends(get_settings)) -> Any:
    if provider not in settings.active_oidc_providers or provider == "mock":
        raise HTTPException(status_code=404, detail=f"provider not active: {provider}")
    oauth = getattr(request.app.state, "oauth", None)
    if oauth is None:
        raise RuntimeError("OAuth client not configured")
    client = oauth.create_client(provider)
    if client is None:
        raise HTTPException(status_code=404, detail=f"provider not registered: {provider}")
    redirect_uri = f"{settings.oidc_redirect_base}{settings.api_prefix}/auth/callback/{provider}"
    return await client.authorize_redirect(request, redirect_uri)


@router.get("/callback/{provider}")
async def callback(
    provider: str,
    request: Request,
    settings: Settings = Depends(get_settings),
    service: AuthService = Depends(get_auth_service),
) -> RedirectResponse:
    if provider == "mock":
        raise HTTPException(status_code=404, detail="mock has no callback; use /auth/login/mock")
    oauth = getattr(request.app.state, "oauth", None)
    if oauth is None:
        raise RuntimeError("OAuth client not configured")
    client = oauth.create_client(provider)
    if client is None:
        raise HTTPException(status_code=404, detail=f"provider not registered: {provider}")
    token = await client.authorize_access_token(request)
    claims: dict[str, Any] = token.get("userinfo") or {}
    if not claims:
        # GitHub 등 OIDC 외 공급자는 userinfo 가 빠짐 → API 호출.
        if provider == "github":
            resp = await client.get("user", token=token)
            claims = resp.json()
            claims.setdefault("sub", str(claims.get("id", "")))
            if not claims.get("email"):
                emails = (await client.get("user/emails", token=token)).json()
                primary = next((e for e in emails if e.get("primary")), None)
                if primary:
                    claims["email"] = primary["email"]
        else:
            claims = await client.userinfo(token=token)

    user = await service.upsert_user_from_oidc(provider, dict(claims))
    session = await service.create_session(user.id)

    secure = settings.environment in ("staging", "production")
    redirect = RedirectResponse(url=settings.oidc_post_login_redirect, status_code=302)
    _set_session_cookie(redirect, settings.session_cookie_name, session.id, settings.session_ttl_hours, secure)
    return redirect


# 세션 가드 사용 예시 — 다른 라우터에서 require_user 를 그대로 Depends.
__all__ = ["router", "get_current_user", "require_user"]
