#!/usr/bin/env bash
# Prod MongoDB → mongodump → tar.gz to {{prod_backup_dir}}.
set -euo pipefail
cd "$(dirname "$0")/.."

ts=$(date -u +'%Y%m%dT%H%M%SZ')
out_dir="{{prod_backup_dir}}/$ts"
mkdir -p "$out_dir"

container="{{db_container_prefix}}-mongodb-prod"
docker exec "$container" mongodump --archive=/tmp/dump.archive --gzip
docker cp "$container":/tmp/dump.archive "$out_dir/dump.archive"
docker exec "$container" rm -f /tmp/dump.archive

echo "✓ backup created at $out_dir/dump.archive"
ls -lh "$out_dir"
