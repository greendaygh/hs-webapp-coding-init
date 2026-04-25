#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose -f assets/docker/docker-compose.staging.yml down
echo "✓ staging stack stopped"
