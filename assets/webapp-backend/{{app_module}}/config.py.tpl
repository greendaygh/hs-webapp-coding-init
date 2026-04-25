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

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
