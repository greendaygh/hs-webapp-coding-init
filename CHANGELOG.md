# Changelog

이 프로젝트의 모든 주요 변경사항은 이 파일에 기록됩니다. 형식은 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)를 따르고, 버저닝은 [SemVer](https://semver.org/lang/ko/)를 따릅니다.

## [v0.1.3] - 2026-04-26

Phase 3 — Staging stack (Let's Encrypt test-acme).

### Added
- **`Caddyfile.staging`** 자산: `staging.{{proxy_domain}}` 도메인 + Let's Encrypt **staging CA**(`acme-staging-v02`) 사용으로 prod 발급 rate-limit를 피하고 인증서 자동화/리허설을 안전하게 수행. 보안 헤더에 `X-Robots-Tag: noindex, nofollow` 추가 (검색 노출 방지).
- **`assets/docker/docker-compose.staging.yml`** 자산: prod 스택과 동일 구성이지만 `restart: unless-stopped`, 컨테이너 접미사 `-staging`, `staging_port`(기본 8080) 매핑, `.env.staging` 사용, 데이터 디렉터리 `{{prod_data_dir}}/staging/...`로 격리.
- **`scripts/start-staging.sh` / `scripts/stop-staging.sh`**: prod 스크립트와 동형이며, `validate-env.sh staging`을 선행 호출하여 `CHANGE_ME` placeholder가 있으면 fail-fast.
- `reverse-proxy-caddy` 자산이 prod + staging 두 Caddyfile을 함께 설치하도록 확장 (별도 자산 분리 없이 fullstack 프리셋에 자동 포함).
- **회귀 테스트 4건** 추가 (총 61개).

## [v0.1.2] - 2026-04-26

Phase 2 — Reproducibility + Security harness.

### Added
- **Reproducibility**: `.tool-versions` 자산 추가 (asdf/mise 호환 — `nodejs {{node_version}}` / `python {{python_version}}`).
- **Security 워크플로** (`.github/workflows/security.yml`): 4종 스캐너를 한 번에 실행하고 매주 월요일 정기 스캔.
  - **gitleaks**: Git 이력 시크릿 누출 검사.
  - **bandit**: Python SAST (백엔드 `{{app_module}}` 한정, `tests/` 제외).
  - **pip-audit**: Python 의존성 CVE 검사 (`requirements.txt`/`pyproject.toml` 자동 인식, `--strict`).
  - **npm audit**: 프론트엔드 의존성 CVE 검사 (`--audit-level=high`).
- **bandit pre-commit hook**: 커밋 직전 백엔드 코드만 검사 (`-ll -ii`, `tests/` 제외) → 머지 전 빠른 피드백.
- **백엔드 dev deps** 3종(poetry/pip/conda) 모두에 `bandit[toml]>=1.7`, `pip-audit>=2.7` 추가.
- **`webapp-fullstack`/`webapp-fullstack-poetry`/`webapp-fullstack-conda` 프리셋**에 `repro-tool-versions` + `security-scan` 자산 포함 (기본 활성).
- **CHANGE_ME fail-fast 회귀 테스트**: `scripts/validate-env.sh production`이 `CHANGE_ME` placeholder를 발견하면 비-0 종료하는지 검증 (이미 존재하던 동작에 회귀 방지).
- **회귀 테스트 5건** 추가 (총 57개 통합/단위 테스트, 4건 신규 + 1건 회귀).

## [v0.1.1] - 2026-04-26

Phase 1 — Observability + Data harness.

### Added
- **Observability**: backend `app/logging_config.py` (dictConfig + Request ID context filter, dev=콘솔/그 외=JSON) 자산 추가, `main.py`가 부팅 시 `configure_logging()` 호출.
- **`/health/ready` dependency check**: `register_dependency_check(app, "db", _ping)` 패턴으로 외부 의존성 검사를 등록하면, 모든 검사 통과 시 `200 {status: "ready"}` / 하나라도 실패 시 `503 {status: "degraded", checks: {...}}`.
- **Frontend ErrorBoundary**: `src/components/ErrorBoundary.tsx` 자산 추가 (React 18 클래스 컴포넌트 + Sentry hook 자리).
- **Data harness**: `tests/factories.py` factory_boy + faker 스텁 자산 + 백엔드 dev deps에 `factory-boy`, `faker` 추가 (poetry/pip/conda 3종 모두).
- **회귀 테스트 5건** 추가 (총 52개 통합/단위 테스트).


첫 공개 릴리스. FastAPI + React + MongoDB + Caddy 풀스택 부트스트래퍼.

### Added
- **CLI 커맨드 4종**: `init` / `list` / `add` / `preset`.
- **8개 preset**: `webapp-fullstack`, `webapp-fullstack-poetry`, `webapp-fullstack-conda`, `webapp-backend`, `webapp-frontend`, `quality-essentials`, `cursor-rules-only`, `ops-only`.
- **18개 자산**: Cursor TDD/auto-versioning 룰, FastAPI DDD 스캐폴드, React+Vite features 구조, MongoDB 데이터 볼륨, Docker Compose 3종(dev/staging/prod), Caddy 리버스 프록시, `.env` 4환경, pre-commit + ruff/mypy/eslint/prettier, GitHub Actions CI, Playwright + MSW, 문서 카탈로그.
- **TDD 1일차 그린**: 생성 직후 `bash scripts/test-all.sh`가 venv-aware로 백엔드(poetry/.venv/conda 자동 감지) + 프론트엔드 테스트를 통과시킵니다. e2e는 실서비스 의존이라 `RUN_E2E=1`일 때만 실행.
- **Preset-aware Next-steps 안내**: poetry/conda/pip preset에 맞는 의존성 설치 명령을 우선 표시.
- **변수 치환 엔진**: `{{var}}` 토큰 치환 + 4가지 install action(`copy`, `merge-json`, `append`, `exec`).
- **Idempotent 재실행**: marker 기반 append + 깊은 JSON merge로 같은 명령을 여러 번 실행해도 중복 없이 안전.
- **Harness 문서**: `docs/HARNESS.md` 등 10종 문서 카탈로그로 onboarding 30분 컷 가이드 제공.
- **47개 단위/통합 테스트** 그린 (회귀 방지 케이스 포함).
