"""Auth API 통합 테스트 — TestClient + OIDC mock provider 경로.

실제 IdP 콜백(`/auth/login/google` 등)은 authlib 가 외부 호출을 하므로
respx 기반 흐름은 별도 케이스로 분리할 수 있다. 여기서는 mock provider 경로로
세션 생명주기(login → me → logout → me 401)를 검증한다.
"""
from __future__ import annotations

from fastapi.testclient import TestClient


def test_providers_list_includes_mock_in_test(client: TestClient) -> None:
    res = client.get("{{api_v1_prefix}}/auth/providers")
    assert res.status_code == 200
    body = res.json()
    assert "providers" in body
    assert "mock" in body["providers"]


def test_me_unauthenticated_returns_401(client: TestClient) -> None:
    res = client.get("{{api_v1_prefix}}/auth/me")
    assert res.status_code == 401


def test_mock_login_creates_session_and_me_returns_user(client: TestClient) -> None:
    login = client.get(
        "{{api_v1_prefix}}/auth/login/mock",
        params={"email": "alice@example.com", "name": "Alice"},
        follow_redirects=False,
    )
    assert login.status_code in (302, 307)
    # cookie 가 응답에 박혀야 함
    assert "sid" in login.cookies or "sid" in client.cookies

    res = client.get("{{api_v1_prefix}}/auth/me")
    assert res.status_code == 200
    body = res.json()
    assert body["email"] == "alice@example.com"
    assert body["provider"] == "mock"


def test_logout_invalidates_session(authed_client: TestClient) -> None:
    res = authed_client.get("{{api_v1_prefix}}/auth/me")
    assert res.status_code == 200

    out = authed_client.post("{{api_v1_prefix}}/auth/logout")
    assert out.status_code == 200
    assert out.json()["ok"] is True

    after = authed_client.get("{{api_v1_prefix}}/auth/me")
    assert after.status_code == 401


def test_login_unknown_provider_returns_404(client: TestClient) -> None:
    res = client.get("{{api_v1_prefix}}/auth/login/twitter", follow_redirects=False)
    assert res.status_code == 404
