#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for f in {{pid_dir}}/backend.pid {{pid_dir}}/frontend.pid; do
  [[ -f "$f" ]] || continue
  pid=$(cat "$f")
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" || true
    echo "✓ killed pid $pid ($f)"
  fi
  rm -f "$f"
done

bash scripts/stop-db.sh || true
