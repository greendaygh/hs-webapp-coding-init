"""User & Session — 인증 도메인.

- `User`: 시스템에 영속되는 식별 주체. OIDC 공급자(provider) + 공급자 내부 sub 가 자연 키.
- `Session`: 발급된 서명 쿠키 세션의 값 객체. 만료시각으로 폐기.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


@dataclass
class User:
    """OIDC 콜백 claims 로부터 upsert 되는 사용자."""

    id: str
    provider: str  # "google" | "github" | "mock"
    sub: str  # 공급자 내부 사용자 식별자 (안정 키)
    email: str
    name: str = ""
    roles: list[str] = field(default_factory=list)
    created_at: datetime = field(default_factory=_utcnow)


@dataclass
class Session:
    """서명 쿠키에 sid 만 박힘. 본문은 DB 의 sessions 컬렉션."""

    id: str
    user_id: str
    expires_at: datetime
    created_at: datetime = field(default_factory=_utcnow)

    def is_expired(self, now: datetime | None = None) -> bool:
        return (now or _utcnow()) >= self.expires_at

    @classmethod
    def new(cls, sid: str, user_id: str, ttl_hours: int) -> "Session":
        return cls(id=sid, user_id=user_id, expires_at=_utcnow() + timedelta(hours=ttl_hours))
