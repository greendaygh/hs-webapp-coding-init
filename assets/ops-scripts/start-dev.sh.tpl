#!/usr/bin/env bash
# {{project_name}} — 개발 모드: DB는 docker, 백/프론트는 host
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p {{log_dir}} {{pid_dir}}

bash scripts/validate-env.sh development

bash scripts/start-db.sh

# Backend (uvicorn --reload)
(
  cd {{backend_dir}}
  ENVIRONMENT=development uvicorn {{app_module}}.main:app \
    --host 0.0.0.0 --port {{backend_dev_port}} --reload \
    > ../{{log_dir}}/backend.log 2>&1 &
  echo $! > ../{{pid_dir}}/backend.pid
)

# Frontend (Vite)
(
  cd {{frontend_dir}}
  npm run dev > ../{{log_dir}}/frontend.log 2>&1 &
  echo $! > ../{{pid_dir}}/frontend.pid
)

echo "✓ dev stack starting"
echo "  backend: http://localhost:{{backend_dev_port}}"
echo "  frontend: http://localhost:{{frontend_dev_port}}"
echo "  logs: tail -f {{log_dir}}/backend.log {{log_dir}}/frontend.log"
echo "  stop: bash scripts/stop-dev.sh"
