"""Structured logging (dictConfig) with Request ID context binding.

- dev: 컬러 콘솔 포맷
- 그 외(staging/production): JSON 라인 (1줄 = 1 이벤트)

`bind_request_id(request_id)` 컨텍스트 매니저 또는 미들웨어에서 contextvar에
값을 설정하면, 모든 로그 레코드에 `request_id` 필드가 자동으로 들어간다.
"""
from __future__ import annotations

import json
import logging
import logging.config
import sys
from contextvars import ContextVar
from typing import Any

_request_id_ctx: ContextVar[str] = ContextVar("request_id", default="-")


def get_request_id() -> str:
    return _request_id_ctx.get()


def set_request_id(rid: str) -> None:
    _request_id_ctx.set(rid)


class RequestIdFilter(logging.Filter):
    """모든 LogRecord에 `request_id` 필드를 부착."""

    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = get_request_id()
        return True


class JsonFormatter(logging.Formatter):
    """1줄 = 1 JSON 이벤트. prod/staging에서 사용."""

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "ts": self.formatTime(record, "%Y-%m-%dT%H:%M:%S"),
            "level": record.levelname,
            "logger": record.name,
            "msg": record.getMessage(),
            "request_id": getattr(record, "request_id", "-"),
        }
        if record.exc_info:
            payload["exc"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False)


def build_dict_config(env: str, level: str = "INFO") -> dict[str, Any]:
    is_dev = env in ("development", "test")
    formatter_id = "console" if is_dev else "json"
    return {
        "version": 1,
        "disable_existing_loggers": False,
        "filters": {
            "request_id": {"()": "{{app_module}}.logging_config.RequestIdFilter"},
        },
        "formatters": {
            "console": {
                "format": "%(asctime)s %(levelname)s [%(request_id)s] %(name)s: %(message)s",
                "datefmt": "%H:%M:%S",
            },
            "json": {"()": "{{app_module}}.logging_config.JsonFormatter"},
        },
        "handlers": {
            "default": {
                "class": "logging.StreamHandler",
                "stream": sys.stdout,
                "formatter": formatter_id,
                "filters": ["request_id"],
            },
        },
        "root": {"handlers": ["default"], "level": level},
        "loggers": {
            "uvicorn.error": {"level": level},
            "uvicorn.access": {"level": level},
        },
    }


def configure_logging(env: str, level: str = "INFO") -> None:
    """`get_settings()` 결과를 받아 호출. 멱등성 보장."""
    logging.config.dictConfig(build_dict_config(env, level))
