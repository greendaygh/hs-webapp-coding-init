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
