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
