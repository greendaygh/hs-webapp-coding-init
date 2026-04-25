# hs-webapp-coding-init

[![npm version](https://img.shields.io/npm/v/hs-webapp-coding-init.svg)](https://www.npmjs.com/package/hs-webapp-coding-init)
[![npm downloads](https://img.shields.io/npm/dm/hs-webapp-coding-init.svg)](https://www.npmjs.com/package/hs-webapp-coding-init)
[![license](https://img.shields.io/npm/l/hs-webapp-coding-init.svg)](https://github.com/greendaygh/hs-webapp-coding-init/blob/main/LICENSE)
[![node](https://img.shields.io/node/v/hs-webapp-coding-init.svg)](https://www.npmjs.com/package/hs-webapp-coding-init)

> FastAPI + React 풀스택 웹앱 부트스트랩 CLI — TDD/Harness/Docs 자산 일괄 설치.

새 프로젝트를 만들 때 매번 반복하는 것들 — DDD 백엔드 골격, features 기반 React, Docker Compose 3종, Caddy 프록시, .env 다중 환경, pre-commit, GitHub Actions, Playwright, MSW, Cursor rules, 운영 스크립트, 문서 카탈로그 — 을 한 명령으로 깔아줍니다.

## Quick Start

```bash
mkdir my-app && cd my-app
npx hs-webapp-coding-init init
```

기본 preset(`webapp-fullstack`)이 적용되며 다음 디렉터리 구조가 생성됩니다:

```
my-app/
├── backend/          FastAPI (DDD: domain/application/infrastructure/api)
├── frontend/         React + Vite (features-based)
├── e2e/              Playwright
├── assets/docker/    Dockerfile.{python,node}, docker-compose.{db-only,dev,prod}.yml
├── scripts/          start/stop-{db,dev,prod}.sh, validate-env.sh, test-all.sh, ...
├── docs/             GETTING_STARTED, DEVELOPMENT, TESTING, ENV_SETUP, DEPLOYMENT, HARNESS
├── .cursor/rules/    TDD / auto-versioning rules
├── .github/workflows/ci.yml
├── Caddyfile.prod
├── .env.{development,staging,production,test}.example
├── README.md / CHANGELOG.md / LICENSE
└── ...
```

곧바로:

```bash
cp .env.development.example .env.development
cd backend && pip install -r requirements-dev.txt
cd ../frontend && npm ci
bash ../scripts/test-all.sh         # backend + frontend 첫 테스트가 그린이어야 함
bash ../scripts/start-dev.sh        # http://localhost:5173
```

## Commands

| 명령 | 설명 |
| --- | --- |
| `hs-webapp-coding-init init` | 인터랙티브 init (preset 선택 + 변수 입력) |
| `hs-webapp-coding-init init --preset <id> --yes` | non-interactive |
| `hs-webapp-coding-init list` | preset / asset 목록 |
| `hs-webapp-coding-init preset [id]` | preset 상세 |
| `hs-webapp-coding-init add <asset-id...>` | 특정 자산만 추가 |

### 주요 옵션

| 옵션 | 의미 |
| --- | --- |
| `--preset <id>` | 사용할 preset (기본 `webapp-fullstack`) |
| `--yes`, `-y` | 모든 prompt 기본값 사용 |
| `--force`, `-f` | 기존 파일 덮어쓰기 (기본은 skip) |
| `--dry-run` | 실제 쓰기 없이 미리 보기 |
| `--no-msw` | MSW(API mock) 비활성화 |
| `--allow-exec` | exec action 허용 (보안 opt-in, 기본 거부) |
| `--var key=value` | 변수 직접 지정 (반복 가능) |

## Presets

| ID | 용도 |
| --- | --- |
| `webapp-fullstack` | FastAPI + React + Docker + Caddy + CI + E2E + Docs (기본 추천) |
| `webapp-fullstack-poetry` | 위 + Poetry |
| `webapp-fullstack-conda` | 위 + Conda |
| `webapp-backend` | FastAPI 백엔드만 |
| `webapp-frontend` | React 프론트엔드만 |
| `quality-essentials` | lint/format/precommit + cursor rules |
| `cursor-rules-only` | Cursor rules만 |
| `ops-only` | 기존 프로젝트에 docker/ops 자산만 추가 |

## Python 패키지 매니저 3변형

| Preset | 결과물 |
| --- | --- |
| `webapp-fullstack` | `backend/pyproject.toml` + `requirements*.txt` (pip) |
| `webapp-fullstack-poetry` | `backend/pyproject.toml` (Poetry) |
| `webapp-fullstack-conda` | `backend/environment.yml` (Conda) |

## TDD 1일차

`init` 직후 다음이 통과합니다:

- `backend/tests/unit/test_health.py` — 3 tests (health/live/ready)
- `frontend/src/App.test.tsx` — 2 tests (render + MSW health mock)

`bash scripts/test-all.sh`로 전부 한 번에 돌려보세요. 그린이면 환경 설정 OK.

## 변수 (자주 쓰는 것)

| 변수 | 기본값 | 설명 |
| --- | --- | --- |
| `project_name` | (디렉터리 이름) | 사람이 읽는 이름 |
| `project_slug` | (자동 생성) | kebab-case, 컨테이너/패키지명에 사용 |
| `backend_dir` | `backend` | |
| `frontend_dir` | `frontend` | |
| `app_module` | `app` | Python 패키지 이름 |
| `db_kind` | `mongodb` | |
| `python_version` | `3.12` | |
| `node_version` | `22` | |
| `frontend_dev_port` | `5173` | |
| `backend_dev_port` | `8000` | |
| `proxy_domain` | `localhost` | Caddy 서비스 도메인 |
| `acme_email` | `admin@<domain>` | Let's Encrypt |
| `default_locale` | `ko` | |
| `coverage_threshold` | `70` | |

전체 변수표는 `src/lib/vars.ts`의 `STANDARD_DEFAULTS`를 참조하세요. 모든 변수는 `--var key=value`로 덮어쓸 수 있습니다.

## 보안 정책

- `--allow-exec` 없이는 `exec` action을 절대 실행하지 않습니다. 임의 패키지 install 등은 `postMessage`로 안내만 합니다.
- 운영(`production`/`staging`) 환경에서 `validate-env.sh`가 `CHANGE_ME` placeholder가 남아 있으면 fail-fast합니다.

## 멱등성

- 같은 디렉터리에서 다시 `init`해도 기본은 **기존 파일 보존**(skip).
- `.gitignore` 등 append 자산은 마커(`hs-webapp-coding-init/<section> >>>...<<<`) 사이만 교체하므로 중복되지 않습니다.

## 라이선스

MIT © 2026
