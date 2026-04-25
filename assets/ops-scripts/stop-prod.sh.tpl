#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose -f assets/docker/docker-compose.prod.yml down
echo "✓ prod stack stopped"
