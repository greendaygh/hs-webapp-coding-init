#!/usr/bin/env bash
# Staging stack 기동 (Let's Encrypt staging CA — 인증서는 브라우저에 untrusted).
# usage: bash scripts/start-staging.sh
set -euo pipefail
cd "$(dirname "$0")/.."

bash scripts/validate-env.sh staging

mkdir -p {{prod_data_dir}}/staging/mongodb {{prod_data_dir}}/staging/mongodb-config

docker compose -f assets/docker/docker-compose.staging.yml --env-file .env.staging up -d --build
echo "✓ staging stack started (port {{staging_port}})"
docker compose -f assets/docker/docker-compose.staging.yml ps
