.PHONY: help install dev db dev-stop db-stop test lint typecheck audit security \
        staging staging-stop prod prod-stop validate backup clean

# ─────────────────────────────────────────────────────────────
# {{project_name}} — 통합 작업 진입점.
# 자세한 내용은 docs/GETTING_STARTED.md 와 docs/HARNESS.md 참조.
# ─────────────────────────────────────────────────────────────

help:                ## 사용 가능한 타겟 목록 출력
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

install:             ## backend + frontend 의존성 설치
	cd {{backend_dir}} && (poetry install || pip install -r requirements-dev.txt || true)
	cd {{frontend_dir}} && npm ci

# ── Dev ─────────────────────────────────────────────────────
db:                  ## DB(Mongo+Redis) 컨테이너만 기동
	bash scripts/start-db.sh

db-stop:             ## DB 컨테이너 종료
	bash scripts/stop-db.sh

dev:                 ## 풀스택 개발 모드 시작 (DB+API+UI)
	bash scripts/start-dev.sh

dev-stop:            ## 개발 모드 종료
	bash scripts/stop-dev.sh

# ── Test/Lint ───────────────────────────────────────────────
test:                ## backend + frontend 테스트 일괄 실행
	bash scripts/test-all.sh

lint:                ## ruff + prettier + eslint
	cd {{backend_dir}} && ruff check . || true
	cd {{frontend_dir}} && npm run lint || true

typecheck:           ## mypy + tsc
	cd {{backend_dir}} && mypy . || true
	cd {{frontend_dir}} && npm run typecheck || true

audit:               ## 의존성 보안 스캔 (pip-audit + npm audit)
	cd {{backend_dir}} && (pip-audit -r requirements.txt --strict || pip-audit . --strict) || true
	cd {{frontend_dir}} && npm audit --audit-level=high || true

security:            ## 정적 보안 검사 (bandit, secrets)
	cd {{backend_dir}} && bandit -r {{app_module}} -ll -ii -x tests || true

# ── Staging/Prod ────────────────────────────────────────────
validate:            ## .env.production / .env.staging 검증 (CHANGE_ME fail-fast)
	bash scripts/validate-env.sh production || true
	bash scripts/validate-env.sh staging || true

staging:             ## Staging 스택 기동 (test-acme TLS)
	bash scripts/start-staging.sh

staging-stop:        ## Staging 스택 종료
	bash scripts/stop-staging.sh

prod:                ## Production 스택 기동 (실 발급 TLS)
	bash scripts/start-prod.sh

prod-stop:           ## Production 스택 종료
	bash scripts/stop-prod.sh

backup:              ## Production DB 백업
	bash scripts/backup-prod-db.sh

# ── Misc ────────────────────────────────────────────────────
clean:               ## 빌드 산출물 / 캐시 정리
	cd {{frontend_dir}} && rm -rf dist node_modules/.vite || true
	cd {{backend_dir}} && find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
