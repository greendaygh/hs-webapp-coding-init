# {{project_name}} — test (CI / local)
ENVIRONMENT=test
DEBUG=true
LOG_LEVEL=WARNING

BACKEND_PORT={{backend_dev_port}}
API_PREFIX={{api_v1_prefix}}
SECRET_KEY=test_secret

DB_KIND=sqlite
MONGODB_URI=mongodb://localhost:{{mongodb_host_port_dev}}
MONGODB_DB={{project_slug}}_test

CORS_ORIGINS=http://localhost:{{frontend_dev_port}}

# Auth (OIDC + 서명 쿠키 세션)
SESSION_SECRET=test-session-secret
SESSION_TTL_HOURS=24
OIDC_REDIRECT_BASE=http://localhost:{{backend_dev_port}}
OIDC_POST_LOGIN_REDIRECT=http://localhost:{{frontend_dev_port}}/
OIDC_MOCK_ENABLED=true
OIDC_GOOGLE_CLIENT_ID=
OIDC_GOOGLE_CLIENT_SECRET=
OIDC_GITHUB_CLIENT_ID=
OIDC_GITHUB_CLIENT_SECRET=
