#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose -f assets/docker/docker-compose.db-only.yml down
echo "✓ DB containers stopped"
