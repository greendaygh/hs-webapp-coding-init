"""AuthService 단위 테스트 — 메모리 fake repo 로 흐름 검증."""
from __future__ import annotations

import pytest

from {{app_module}}.application.auth_service import AuthService
from {{app_module}}.domain.user import Session, User


class _FakeUserRepo:
    def __init__(self) -> None:
        self._by_id: dict[str, User] = {}
        self._by_ps: dict[tuple[str, str], User] = {}

    async def get_by_provider_sub(self, provider: str, sub: str) -> User | None:
        return self._by_ps.get((provider, sub))

    async def get_by_id(self, user_id: str) -> User | None:
        return self._by_id.get(user_id)

    async def upsert(self, user: User) -> User:
        self._by_id[user.id] = user
        self._by_ps[(user.provider, user.sub)] = user
        return user


class _FakeSessionRepo:
    def __init__(self) -> None:
        self._store: dict[str, Session] = {}

    async def create(self, session: Session) -> None:
        self._store[session.id] = session

    async def get(self, sid: str) -> Session | None:
        return self._store.get(sid)

    async def delete(self, sid: str) -> None:
        self._store.pop(sid, None)


@pytest.fixture
def service() -> AuthService:
    return AuthService(_FakeUserRepo(), _FakeSessionRepo(), session_ttl_hours=24)


@pytest.mark.asyncio
async def test_upsert_user_creates_new(service: AuthService) -> None:
    user = await service.upsert_user_from_oidc(
        "google", {"sub": "g-1", "email": "a@b.c", "name": "A"}
    )
    assert user.provider == "google"
    assert user.sub == "g-1"
    assert user.email == "a@b.c"
    assert user.id


@pytest.mark.asyncio
async def test_upsert_user_idempotent_same_provider_sub(service: AuthService) -> None:
    u1 = await service.upsert_user_from_oidc("google", {"sub": "g-1", "email": "a@b.c"})
    u2 = await service.upsert_user_from_oidc("google", {"sub": "g-1", "email": "new@b.c"})
    assert u1.id == u2.id
    assert u2.email == "new@b.c"


@pytest.mark.asyncio
async def test_upsert_user_rejects_missing_sub_or_email(service: AuthService) -> None:
    with pytest.raises(ValueError):
        await service.upsert_user_from_oidc("google", {"email": "a@b.c"})
    with pytest.raises(ValueError):
        await service.upsert_user_from_oidc("google", {"sub": "g-1"})


@pytest.mark.asyncio
async def test_create_and_resolve_session(service: AuthService) -> None:
    user = await service.upsert_user_from_oidc("mock", {"sub": "m-1", "email": "m@b.c"})
    session = await service.create_session(user.id)
    resolved = await service.resolve_session(session.id)
    assert resolved is not None
    assert resolved.id == user.id


@pytest.mark.asyncio
async def test_resolve_session_returns_none_for_missing(service: AuthService) -> None:
    assert await service.resolve_session(None) is None
    assert await service.resolve_session("nope") is None


@pytest.mark.asyncio
async def test_revoke_session_invalidates(service: AuthService) -> None:
    user = await service.upsert_user_from_oidc("mock", {"sub": "m-2", "email": "m2@b.c"})
    session = await service.create_session(user.id)
    await service.revoke_session(session.id)
    assert await service.resolve_session(session.id) is None
