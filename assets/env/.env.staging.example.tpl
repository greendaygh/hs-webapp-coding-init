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
