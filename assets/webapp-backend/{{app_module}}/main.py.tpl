"""FastAPI application entry point."""
from __future__ import annotations

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from {{app_module}}.config import get_settings
from {{app_module}}.api.v1.router import api_router

settings = get_settings()
logging.basicConfig(level=settings.log_level)
logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    app = FastAPI(
        title="{{project_name}}",
        description="{{description}}",
        version="0.1.0",
        docs_url="/docs" if settings.environment != "production" else None,
        redoc_url="/redoc" if settings.environment != "production" else None,
    )

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
    async def readiness() -> dict[str, str]:
        # TODO: DB ping 등 외부 의존성 점검 추가
        return {"status": "ready"}

    logger.info("FastAPI app created (env=%s)", settings.environment)
    return app


app = create_app()
