"""authlib 기반 OIDC client 등록.

Settings 의 client_id/secret 이 모두 채워진 공급자만 등록한다.
새 공급자 추가는 register_*() 함수 한 줄 + Settings 4개 필드.
"""
from __future__ import annotations

from authlib.integrations.starlette_client import OAuth  # type: ignore[import-not-found]

from {{app_module}}.config import Settings

GOOGLE_DISCOVERY = "https://accounts.google.com/.well-known/openid-configuration"


def build_oauth(settings: Settings) -> OAuth:
    """등록된 OIDC 공급자만 갖춘 OAuth 인스턴스 반환."""
    oauth = OAuth()
    if settings.oidc_google_client_id and settings.oidc_google_client_secret:
        oauth.register(
            name="google",
            client_id=settings.oidc_google_client_id,
            client_secret=settings.oidc_google_client_secret,
            server_metadata_url=GOOGLE_DISCOVERY,
            client_kwargs={"scope": "openid email profile"},
        )
    if settings.oidc_github_client_id and settings.oidc_github_client_secret:
        # GitHub 는 정식 OIDC 가 아니지만 OAuth2 로 동일 패턴.
        oauth.register(
            name="github",
            client_id=settings.oidc_github_client_id,
            client_secret=settings.oidc_github_client_secret,
            access_token_url="https://github.com/login/oauth/access_token",
            authorize_url="https://github.com/login/oauth/authorize",
            api_base_url="https://api.github.com/",
            client_kwargs={"scope": "read:user user:email"},
        )
    return oauth
