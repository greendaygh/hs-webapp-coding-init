"""Application settings (Pydantic v2)."""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent


def _select_env_file() -> str:
    """ENVIRONMENT 변수에 따라 .env.<env> 파일을 선택. 미정의 시 .env.development."""
    import os

    env = os.environ.get("ENVIRONMENT", "development").lower()
    candidate = PROJECT_ROOT / f".env.{env}"
    if candidate.exists():
        return str(candidate)
    fallback = PROJECT_ROOT / ".env.development"
    return str(fallback)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=_select_env_file(),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    project_name: str = "{{project_name}}"
    environment: Literal["development", "staging", "production", "test"] = "development"
    debug: bool = True
    log_level: str = "INFO"

    api_prefix: str = "{{api_v1_prefix}}"
    backend_port: int = {{backend_dev_port}}

    cors_origins: str = "{{cors_origins_default}}"

    db_kind: Literal["mongodb", "postgres", "sqlite"] = "{{db_kind}}"
    mongodb_uri: str = "mongodb://localhost:{{mongodb_host_port_dev}}"
    mongodb_db: str = Field(default="{{project_slug}}_dev")

    secret_key: str = "CHANGE_ME"
    access_token_expire_minutes: int = 60 * 24

    # ── Auth (OIDC + 서명 쿠키 세션) ──
    # 새 변수 추가 4단계 체크: .env.*.example → validate-env.sh → 여기 → 사용처.
    session_secret: str = "CHANGE_ME"
    session_ttl_hours: int = 24
    session_cookie_name: str = "sid"
    oidc_redirect_base: str = "http://localhost:{{backend_dev_port}}"
    oidc_post_login_redirect: str = "http://localhost:{{frontend_dev_port}}/"
    oidc_mock_enabled: bool = False
    oidc_google_client_id: str = ""
    oidc_google_client_secret: str = ""
    oidc_github_client_id: str = ""
    oidc_github_client_secret: str = ""

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def active_oidc_providers(self) -> list[str]:
        """env 에 client_id/secret 이 모두 채워진 공급자 + mock(개발용)."""
        providers: list[str] = []
        if self.oidc_google_client_id and self.oidc_google_client_secret:
            providers.append("google")
        if self.oidc_github_client_id and self.oidc_github_client_secret:
            providers.append("github")
        if self.oidc_mock_enabled:
            providers.append("mock")
        return providers


@lru_cache
def get_settings() -> Settings:
    return Settings()
