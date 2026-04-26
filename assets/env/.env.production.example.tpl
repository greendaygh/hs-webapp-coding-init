# {{project_name}} — production
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO

BACKEND_PORT={{backend_dev_port}}
API_PREFIX={{api_v1_prefix}}
SECRET_KEY=CHANGE_ME_prod

DB_KIND={{db_kind}}
MONGODB_URI=mongodb://mongodb:27017
MONGODB_DB={{project_slug}}

CORS_ORIGINS=https://{{proxy_domain}}

VITE_API_BASE_URL=https://{{proxy_domain}}
VITE_BACKEND_ORIGIN=https://{{proxy_domain}}

# Caddy
PROXY_DOMAIN={{proxy_domain}}
ACME_EMAIL={{acme_email}}

# Auth (OIDC + 서명 쿠키 세션)
# production 은 Mock 비활성 강제. SESSION_SECRET 은 `openssl rand -hex 32` 권장.
SESSION_SECRET=CHANGE_ME_prod_session
SESSION_TTL_HOURS=24
OIDC_REDIRECT_BASE=https://{{proxy_domain}}
OIDC_POST_LOGIN_REDIRECT=https://{{proxy_domain}}/
OIDC_MOCK_ENABLED=false
OIDC_GOOGLE_CLIENT_ID=CHANGE_ME
OIDC_GOOGLE_CLIENT_SECRET=CHANGE_ME
OIDC_GITHUB_CLIENT_ID=
OIDC_GITHUB_CLIENT_SECRET=
