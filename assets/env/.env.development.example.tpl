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
