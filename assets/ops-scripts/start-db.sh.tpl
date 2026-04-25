#!/usr/bin/env bash
# {{project_name}} — DB-only start (개발 시 백엔드/프론트는 host에서 실행)
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose -f assets/docker/docker-compose.db-only.yml --env-file .env.development up -d
echo "✓ DB containers started"
docker compose -f assets/docker/docker-compose.db-only.yml ps
