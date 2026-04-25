"""FastAPI application entry point."""
from __future__ import annotations

import logging
from typing import Awaitable, Callable

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

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


def create_app() -> FastAPI:
    app = FastAPI(
        title="{{project_name}}",
        description="{{description}}",
        version="0.1.0",
        docs_url="/docs" if settings.environment != "production" else None,
        redoc_url="/redoc" if settings.environment != "production" else None,
    )
    app.state.dependency_checks = default_dependency_checks()

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

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
