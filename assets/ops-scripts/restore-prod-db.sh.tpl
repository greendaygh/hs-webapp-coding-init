#!/usr/bin/env bash
# Production MongoDB 복원 — backup-prod-db.sh 의 짝.
# usage: bash scripts/restore-prod-db.sh <timestamp_dir> [--yes]
#   <timestamp_dir>: {{prod_backup_dir}}/<UTC_TS> 형태 (e.g. {{prod_backup_dir}}/20260426T091500Z)
#   --yes          : 비대화 모드 (확인 prompt 생략)
#
# 주의: 이 스크립트는 mongorestore --drop 을 사용하므로 대상 DB 의 기존 컬렉션을
#       모두 삭제한 뒤 백업 시점 상태로 되돌립니다. 운영 DB 에 직접 실행하기 전에
#       반드시 staging 에서 리허설하세요. 보관/회전/오프사이트/암호화/알림 정책은
#       이 패키지가 강제하지 않으며 docs/DEPLOYMENT.md 의 체크리스트를 참고해
#       앱별로 결정하십시오.
set -euo pipefail
cd "$(dirname "$0")/.."

assume_yes=0
target=""
for arg in "$@"; do
  case "$arg" in
    --yes|-y) assume_yes=1 ;;
    -*)
      echo "✗ unknown option: $arg" >&2
      echo "  usage: bash scripts/restore-prod-db.sh <timestamp_dir> [--yes]" >&2
      exit 2
      ;;
    *)
      if [[ -n "$target" ]]; then
        echo "✗ unexpected extra argument: $arg" >&2
        exit 2
      fi
      target="$arg"
      ;;
  esac
done

if [[ -z "$target" ]]; then
  echo "✗ missing <timestamp_dir>" >&2
  echo "  usage: bash scripts/restore-prod-db.sh <timestamp_dir> [--yes]" >&2
  echo "  example: bash scripts/restore-prod-db.sh {{prod_backup_dir}}/20260426T091500Z" >&2
  exit 2
fi

if [[ ! -d "$target" ]]; then
  echo "✗ backup dir not found: $target" >&2
  exit 3
fi

archive="$target/dump.archive"
if [[ ! -f "$archive" ]]; then
  echo "✗ dump.archive not found in: $target" >&2
  exit 3
fi

container="{{db_container_prefix}}-mongodb-prod"
if ! docker inspect "$container" >/dev/null 2>&1; then
  echo "✗ container not running: $container" >&2
  echo "  → bash scripts/start-prod.sh" >&2
  exit 4
fi

cat <<EOF
About to restore production MongoDB:
  archive   : $archive
  container : $container
  command   : mongorestore --archive --gzip --drop  (drops existing collections)
EOF

if (( assume_yes == 0 )); then
  read -r -p "Continue? type 'y' to proceed: " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "✗ aborted by user" >&2
    exit 5
  fi
fi

docker cp "$archive" "$container":/tmp/dump.archive
trap 'docker exec "$container" rm -f /tmp/dump.archive >/dev/null 2>&1 || true' EXIT
docker exec "$container" mongorestore --archive=/tmp/dump.archive --gzip --drop

echo "✓ restore complete from $archive"
