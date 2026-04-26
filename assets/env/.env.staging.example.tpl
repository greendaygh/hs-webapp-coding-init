# {{project_name}} — staging
ENVIRONMENT=staging
DEBUG=false
LOG_LEVEL=INFO

BACKEND_PORT={{backend_dev_port}}
API_PREFIX={{api_v1_prefix}}
SECRET_KEY=CHANGE_ME_staging

DB_KIND={{db_kind}}
MONGODB_URI=mongodb://mongodb:27017
MONGODB_DB={{project_slug}}_staging

CORS_ORIGINS=https://staging.{{proxy_domain}}

VITE_API_BASE_URL=https://staging.{{proxy_domain}}
VITE_BACKEND_ORIGIN=https://staging.{{proxy_domain}}

# Auth (OIDC + 서명 쿠키 세션)
# staging/production 은 Mock 비활성 강제 (validate-env.sh 가드).
SESSION_SECRET=CHANGE_ME_staging_session
SESSION_TTL_HOURS=24
OIDC_REDIRECT_BASE=https://staging.{{proxy_domain}}
OIDC_POST_LOGIN_REDIRECT=https://staging.{{proxy_domain}}/
OIDC_MOCK_ENABLED=false
OIDC_GOOGLE_CLIENT_ID=CHANGE_ME
OIDC_GOOGLE_CLIENT_SECRET=CHANGE_ME
OIDC_GITHUB_CLIENT_ID=
OIDC_GITHUB_CLIENT_SECRET=
