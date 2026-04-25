#!/usr/bin/env bash
# {{project_name}} — TDD 1일차 그린: 백엔드 + 프론트 통합 테스트.
# E2E는 실서비스 의존이라 기본 OFF. RUN_E2E=1 환경변수가 있을 때만 실행.
set -euo pipefail
cd "$(dirname "$0")/.."

# venv-aware backend pytest 실행 (poetry / .venv / conda / fallback 자동 선택)
run_backend_pytest() {
  cd "{{backend_dir}}"
  if [[ -f pyproject.toml ]] && grep -q '\[tool.poetry\]' pyproject.toml 2>/dev/null && command -v poetry >/dev/null 2>&1; then
    poetry run pytest -q
  elif [[ -x .venv/bin/pytest ]]; then
    .venv/bin/pytest -q
  elif [[ -n "${CONDA_PREFIX:-}" ]] && [[ -x "${CONDA_PREFIX}/bin/pytest" ]]; then
    "${CONDA_PREFIX}/bin/pytest" -q
  elif command -v python3 >/dev/null 2>&1 && python3 -c "import pytest" 2>/dev/null; then
    python3 -m pytest -q
  else
    echo "✗ pytest not found. Activate venv first or install dev deps." >&2
    return 1
  fi
}

echo "▸ backend tests"
( run_backend_pytest )

echo "▸ frontend tests"
( cd {{frontend_dir}} && npm run test:run )

if [[ "${RUN_E2E:-0}" == "1" ]]; then
  if [[ -d e2e && -f e2e/playwright.config.ts ]]; then
    echo "▸ e2e tests (RUN_E2E=1) — 실서비스가 떠있어야 합니다"
    ( cd e2e && npm test )
  fi
else
  if [[ -d e2e && -f e2e/playwright.config.ts ]]; then
    echo "  (e2e 스킵: 실행하려면 RUN_E2E=1 bash scripts/test-all.sh)"
  fi
fi

echo "✓ all tests passed"
