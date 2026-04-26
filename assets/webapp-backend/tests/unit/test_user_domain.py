"""User/Session 도메인 단위 테스트."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from {{app_module}}.domain.user import Session, User


def test_user_defaults_have_empty_roles() -> None:
    u = User(id="u1", provider="google", sub="g-1", email="a@b.c", name="A")
    assert u.roles == []
    assert u.created_at.tzinfo is timezone.utc


def test_session_new_ttl_in_future() -> None:
    s = Session.new("sid-1", user_id="u1", ttl_hours=24)
    assert not s.is_expired()
    assert s.expires_at > datetime.now(timezone.utc)


def test_session_is_expired_when_past_expiry() -> None:
    past = datetime.now(timezone.utc) - timedelta(seconds=1)
    s = Session(id="sid", user_id="u1", expires_at=past)
    assert s.is_expired()
