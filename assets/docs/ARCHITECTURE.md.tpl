# Architecture — {{project_name}}

## 큰 그림

```
            ┌─────────────────────────────────────┐
  Browser → │ Caddy (TLS, path routing)          │
            │   /api/v1/* → backend:{{backend_dev_port}}        │
            │   /health/* → backend:{{backend_dev_port}}        │
            │   /*        → frontend:80          │
            └──┬─────────────────────────┬────────┘
               │                         │
        ┌──────▼──────┐           ┌──────▼──────┐
        │  Backend    │           │  Frontend   │
        │  FastAPI    │  ──HTTP→  │ React+Vite  │
        │  (DDD)      │           │ (features)  │
        └──┬──────────┘           └─────────────┘
           │
   ┌───────▼───────┐
   │ MongoDB / Redis │
   └────────────────┘
```

## 백엔드 — Domain-Driven Design (DDD) 4층

`{{backend_dir}}/{{app_module}}/`

| 레이어 | 디렉터리 | 책임 | 의존 방향 |
| --- | --- | --- | --- |
| **api** | `api/v1/` | HTTP 라우팅, request/response 스키마 | application 호출 |
| **application** | `application/` | 유스케이스, 트랜잭션 경계 | domain 호출 |
| **domain** | `domain/` | 엔티티, 값 객체, 도메인 서비스, 도메인 이벤트 | 외부 의존 없음 (pure) |
| **infrastructure** | `infrastructure/` | DB/외부 API/캐시 어댑터 | domain 인터페이스 구현 |

> **의존 방향은 한 방향**: `api → application → domain ← infrastructure`. domain은 외부를 알지 않습니다 (단방향 의존, ports & adapters).

### 횡단 모듈

- `config.py` — Pydantic Settings (단일 출처 환경 변수).
- `logging_config.py` — `logging.config.dictConfig` + Request ID context filter (Phase 1).
- `main.py` — FastAPI app factory, 미들웨어, `/health/*` 엔드포인트, dependency check 등록.

### 의존성 주입

FastAPI `Depends()`로 application → infrastructure 어댑터를 주입. 테스트에서는 `app.dependency_overrides`로 fake 어댑터 교체.

## 프론트엔드 — Features-based

`{{frontend_dir}}/src/`

```
src/
├── features/         # 도메인 단위(예: features/auth, features/posts)
│   └── <feature>/
│       ├── api.ts        # 백엔드 호출 (axios/fetch)
│       ├── hooks.ts      # React hooks (useQuery 등)
│       ├── components/   # UI
│       └── types.ts
├── components/       # 도메인 무관 공통 UI (ErrorBoundary 등)
├── lib/              # 횡단 유틸 (date, format, ...)
├── routes/           # 라우팅 트리
├── mocks/            # MSW handlers (선택)
└── test/             # 테스트 setup
```

> 한 feature 안의 코드는 다른 feature를 직접 import하지 않습니다. 공유가 필요하면 `lib/` 또는 `components/`로 승격.

## 데이터/상태

- **서버 상태**: TanStack Query 권장 (캐시 + 재요청).
- **클라이언트 상태**: React state + Context. 전역 store는 꼭 필요할 때만.

## 배포 토폴로지

| 환경 | 도메인 | TLS CA | Compose 파일 |
| --- | --- | --- | --- |
| development | localhost | (없음) | `docker-compose.dev.yml` (DB만) + host process |
| staging | staging.{{proxy_domain}} | Let's Encrypt **staging** (test-acme) | `docker-compose.staging.yml` (full stack) |
| production | {{proxy_domain}} | Let's Encrypt **production** | `docker-compose.prod.yml` (full stack) |

## 변수 단일 출처

- 코드/설정 곳곳에 흩어진 값을 막기 위해 모든 변수는 `STANDARD_DEFAULTS`(런타임은 환경 변수, 부팅 시 `Settings`로 통합)에 모입니다.
- 새 변수 추가 시: `.env.*.example` → `validate-env.sh` `required[]` → `config.py` `Settings` 필드 → 사용처.

## 관측성 (Phase 1)

- `/health/live` — 프로세스 살아있음 (외부 의존 X).
- `/health/ready` — 등록된 dependency check가 모두 통과해야 200, 하나라도 실패 시 503 + 어떤 검사가 실패했는지 응답에 포함.
- 구조화 로그(JSON, 프로덕션) + Request ID 컨텍스트(`X-Request-Id` 헤더 또는 자동 생성)로 분산 요청 추적.

## 보안 (Phase 2)

- gitleaks(시크릿), bandit(SAST), pip-audit/npm audit(CVE) 4종을 push/PR/매주 정기 실행.
- bandit pre-commit으로 머지 전 빠른 피드백.
- production/staging은 `validate-env.sh`가 `CHANGE_ME` placeholder를 fail-fast 검출.

## 배포 (Phase 4)

- `develop` 또는 `staging-*` 태그 → `deploy-staging.yml` → SSH rsync + staging compose up + smoke.
- `v*` 태그 → `deploy-production.yml` → 원격 validate-env → prod compose up + smoke. GitHub Environments **production** Required reviewers로 수동 승인 게이트.
