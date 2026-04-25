#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

bash scripts/validate-env.sh production

mkdir -p {{prod_data_dir}}/mongodb {{prod_data_dir}}/mongodb-config

docker compose -f assets/docker/docker-compose.prod.yml --env-file .env.production up -d --build
echo "✓ prod stack started"
docker compose -f assets/docker/docker-compose.prod.yml ps
