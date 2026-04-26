# {{project_name}} — development
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=DEBUG

# Backend
BACKEND_PORT={{backend_dev_port}}
API_PREFIX={{api_v1_prefix}}
SECRET_KEY=CHANGE_ME_dev

# Database
DB_KIND={{db_kind}}
MONGODB_URI=mongodb://localhost:{{mongodb_host_port_dev}}
MONGODB_DB={{project_slug}}_dev

# CORS
CORS_ORIGINS={{cors_origins_default}}

# Frontend (Vite envDir)
VITE_API_BASE_URL=
VITE_BACKEND_ORIGIN=http://localhost:{{backend_dev_port}}

# Auth (OIDC + 서명 쿠키 세션)
# dev 는 Mock provider 만으로 로그인 흐름 시연 가능. 실제 IdP 사용 시 client_id/secret 채움.
SESSION_SECRET=CHANGE_ME_dev_session
SESSION_TTL_HOURS=24
OIDC_REDIRECT_BASE=http://localhost:{{backend_dev_port}}
OIDC_POST_LOGIN_REDIRECT=http://localhost:{{frontend_dev_port}}/
OIDC_MOCK_ENABLED=true
OIDC_GOOGLE_CLIENT_ID=
OIDC_GOOGLE_CLIENT_SECRET=
OIDC_GITHUB_CLIENT_ID=
OIDC_GITHUB_CLIENT_SECRET=
