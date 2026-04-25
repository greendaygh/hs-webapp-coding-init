#!/usr/bin/env bash
# 필수 env 변수 + CHANGE_ME placeholder 검증.
# usage: bash scripts/validate-env.sh [development|staging|production|test]
set -euo pipefail

env_name="${1:-development}"
env_file=".env.${env_name}"

if [[ ! -f "$env_file" ]]; then
  echo "✗ env file not found: $env_file" >&2
  echo "  → cp ${env_file}.example $env_file" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a
source "$env_file"
set +a

required=(ENVIRONMENT BACKEND_PORT API_PREFIX SECRET_KEY MONGODB_URI MONGODB_DB)
missing=()
for k in "${required[@]}"; do
  if [[ -z "${!k:-}" ]]; then
    missing+=("$k")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo "✗ missing required env vars in $env_file:" >&2
  for k in "${missing[@]}"; do echo "  - $k" >&2; done
  exit 2
fi

if [[ "$env_name" == "production" || "$env_name" == "staging" ]]; then
  changeme=$(grep -E '^[A-Z_]+=CHANGE_ME' "$env_file" || true)
  if [[ -n "$changeme" ]]; then
    echo "✗ CHANGE_ME placeholders detected in $env_file (refusing to start ${env_name}):" >&2
    echo "$changeme" >&2
    exit 3
  fi
fi

echo "✓ env validated: $env_file"
