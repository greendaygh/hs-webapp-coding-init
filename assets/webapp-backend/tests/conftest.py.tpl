"""Test fixtures shared across the suite."""
from __future__ import annotations

import os
from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient


os.environ.setdefault("ENVIRONMENT", "test")


def _build_memory_auth_service():
    """테스트용 메모리 AuthService — 외부 Mongo 의존성 제거."""
    from {{app_module}}.application.auth_service import AuthService
    from {{app_module}}.domain.user import Session, User

    class _UserRepo:
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

    class _SessionRepo:
        def __init__(self) -> None:
            self._store: dict[str, Session] = {}

        async def create(self, session: Session) -> None:
            self._store[session.id] = session

        async def get(self, sid: str) -> Session | None:
            return self._store.get(sid)

        async def delete(self, sid: str) -> None:
            self._store.pop(sid, None)

    return AuthService(_UserRepo(), _SessionRepo(), session_ttl_hours=24)


@pytest.fixture(scope="session")
def app():
    from {{app_module}}.main import create_app

    a = create_app()
    # 운영 main.py 가 Motor 어댑터를 꽂아 두지만, 테스트는 메모리 어댑터로 교체.
    a.state.auth_service = _build_memory_auth_service()
    return a


@pytest.fixture
def client(app) -> Iterator[TestClient]:
    with TestClient(app) as c:
        yield c


@pytest.fixture
def authed_client(client: TestClient) -> TestClient:
    """OIDC mock 으로 로그인된 TestClient. cookies 가 자동 보관됨.

    .env.test.example 의 OIDC_MOCK_ENABLED=true 가 전제.
    """
    res = client.get(
        "{{api_v1_prefix}}/auth/login/mock",
        params={"email": "tester@example.com"},
        follow_redirects=False,
    )
    assert res.status_code in (302, 307), f"mock login failed: {res.status_code} {res.text}"
    return client
