"""FastAPI application entry point."""
from __future__ import annotations

import logging
from typing import Awaitable, Callable

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.middleware.sessions import SessionMiddleware

from {{app_module}}.config import get_settings
from {{app_module}}.api.v1.router import api_router
from {{app_module}}.logging_config import configure_logging

settings = get_settings()
configure_logging(settings.environment, settings.log_level)
logger = logging.getLogger(__name__)


# /health/ready 의존성 검사. 이름→async 검사 함수 매핑.
# - True 반환: 의존성 OK
# - False/예외: 의존성 NOT OK (전체 응답 503)
# 사용자는 motor.AsyncIOMotorClient.admin.command("ping") 등을
# 등록 시점에 추가한다.
DependencyCheck = Callable[[], Awaitable[bool]]


def default_dependency_checks() -> dict[str, DependencyCheck]:
    """기본은 빈 dict — 의존성 추가 시 override 또는 register_dependency_check() 호출.

    예시:
        async def _ping_db() -> bool:
            ...
        register_dependency_check(app, "db", _ping_db)
    """
    return {}


def register_dependency_check(app: FastAPI, name: str, check: DependencyCheck) -> None:
    checks: dict[str, DependencyCheck] = getattr(app.state, "dependency_checks", {})
    checks[name] = check
    app.state.dependency_checks = checks


async def run_dependency_checks(app: FastAPI) -> tuple[bool, dict[str, str]]:
    checks: dict[str, DependencyCheck] = getattr(app.state, "dependency_checks", {})
    results: dict[str, str] = {}
    all_ok = True
    for name, check in checks.items():
        try:
            ok = await check()
            results[name] = "ok" if ok else "fail"
            if not ok:
                all_ok = False
        except Exception as exc:  # noqa: BLE001
            results[name] = f"error: {exc.__class__.__name__}"
            all_ok = False
    return all_ok, results


def _enforce_auth_safety(s) -> None:  # noqa: ANN001
    """OIDC_MOCK_ENABLED=true 는 dev/test 에서만 허용. prod/staging 에서 켜지면 부팅 실패."""
    if s.oidc_mock_enabled and s.environment in ("production", "staging"):
        raise RuntimeError(
            f"OIDC_MOCK_ENABLED=true is not allowed in {s.environment}. "
            "Set OIDC_MOCK_ENABLED=false."
        )


def _wire_auth(app: FastAPI, s) -> None:  # noqa: ANN001
    """auth_service 와 OAuth client 를 app.state 에 등록.

    test 환경은 conftest 가 메모리 어댑터로 덮어쓴다 (외부 Mongo 의존성 제거).
    """
    if s.environment == "test":
        return
    try:  # 운영 경로: Motor 기반.
        from motor.motor_asyncio import AsyncIOMotorClient

        from {{app_module}}.application.auth_service import AuthService
        from {{app_module}}.infrastructure.oidc_clients import build_oauth
        from {{app_module}}.infrastructure.session_repo import MongoSessionRepo
        from {{app_module}}.infrastructure.user_repo import MongoUserRepo

        client = AsyncIOMotorClient(s.mongodb_uri)
        db = client[s.mongodb_db]
        user_repo = MongoUserRepo(db)
        session_repo = MongoSessionRepo(db)
        app.state.auth_service = AuthService(user_repo, session_repo, s.session_ttl_hours)
        app.state.oauth = build_oauth(s)
        app.state.user_repo = user_repo
        app.state.session_repo = session_repo
    except Exception as exc:  # noqa: BLE001
        logger.warning("auth wiring failed (will be inert until configured): %s", exc)


def create_app() -> FastAPI:
    _enforce_auth_safety(settings)

    app = FastAPI(
        title="{{project_name}}",
        description="{{description}}",
        version="0.1.0",
        docs_url="/docs" if settings.environment != "production" else None,
        redoc_url="/redoc" if settings.environment != "production" else None,
    )
    app.state.dependency_checks = default_dependency_checks()

    # OIDC state 보관용 짧은 쿠키 (authlib 가 사용). 세션 쿠키와 별도.
    app.add_middleware(
        SessionMiddleware,
        secret_key=settings.session_secret,
        same_site="lax",
        https_only=settings.environment in ("staging", "production"),
        max_age=600,  # 10분 — OIDC 콜백 라운드트립용
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    _wire_auth(app, settings)
    app.include_router(api_router, prefix=settings.api_prefix)

    @app.get("{{health_endpoint}}")
    async def health() -> dict[str, str]:
        return {"status": "ok", "env": settings.environment}

    @app.get("{{health_endpoint}}/live")
    async def liveness() -> dict[str, str]:
        return {"status": "live"}

    @app.get("{{health_endpoint}}/ready")
    async def readiness() -> JSONResponse:
        all_ok, checks = await run_dependency_checks(app)
        body = {"status": "ready" if all_ok else "degraded", "checks": checks}
        return JSONResponse(body, status_code=200 if all_ok else 503)

    logger.info("FastAPI app created (env=%s)", settings.environment)
    return app


app = create_app()
