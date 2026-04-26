"""Auth use cases — OIDC 콜백/세션 발급/조회/폐기.

`UserRepo`/`SessionRepo` 는 Protocol 로 추상화. infrastructure 가 Motor 구현 제공.
테스트에서는 메모리 fake 를 주입할 수 있다.
"""
from __future__ import annotations

import secrets
from typing import Any, Protocol

from {{app_module}}.domain.user import Session, User


class UserRepo(Protocol):
    async def get_by_provider_sub(self, provider: str, sub: str) -> User | None: ...
    async def get_by_id(self, user_id: str) -> User | None: ...
    async def upsert(self, user: User) -> User: ...


class SessionRepo(Protocol):
    async def create(self, session: Session) -> None: ...
    async def get(self, sid: str) -> Session | None: ...
    async def delete(self, sid: str) -> None: ...


def _new_id() -> str:
    return secrets.token_urlsafe(16)


def _new_session_id() -> str:
    return secrets.token_urlsafe(32)


class AuthService:
    """애플리케이션 서비스. 도메인 + repo 어댑터를 조립."""

    def __init__(
        self,
        users: UserRepo,
        sessions: SessionRepo,
        session_ttl_hours: int,
    ) -> None:
        self._users = users
        self._sessions = sessions
        self._ttl_hours = session_ttl_hours

    async def upsert_user_from_oidc(self, provider: str, claims: dict[str, Any]) -> User:
        """OIDC userinfo/claims 로부터 사용자를 등록하거나 갱신."""
        sub = str(claims.get("sub") or claims.get("id") or "")
        email = str(claims.get("email") or "")
        if not sub or not email:
            raise ValueError(f"OIDC claims missing sub/email: keys={list(claims)}")
        name = str(claims.get("name") or claims.get("preferred_username") or email.split("@")[0])

        existing = await self._users.get_by_provider_sub(provider, sub)
        if existing is not None:
            existing.email = email
            existing.name = name
            return await self._users.upsert(existing)

        user = User(id=_new_id(), provider=provider, sub=sub, email=email, name=name)
        return await self._users.upsert(user)

    async def create_session(self, user_id: str) -> Session:
        session = Session.new(_new_session_id(), user_id, self._ttl_hours)
        await self._sessions.create(session)
        return session

    async def resolve_session(self, sid: str | None) -> User | None:
        if not sid:
            return None
        session = await self._sessions.get(sid)
        if session is None or session.is_expired():
            if session is not None:
                await self._sessions.delete(sid)
            return None
        return await self._users.get_by_id(session.user_id)

    async def revoke_session(self, sid: str | None) -> None:
        if sid:
            await self._sessions.delete(sid)
