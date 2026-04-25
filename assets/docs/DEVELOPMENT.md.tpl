# Development — {{project_name}}

## 디렉터리 구조

```
.
├── {{backend_dir}}/          FastAPI (DDD: domain/application/infrastructure/api)
│   ├── {{app_module}}/
│   └── tests/                pytest (unit / integration)
├── {{frontend_dir}}/         React + Vite (features-based src/)
│   └── src/
│       ├── features/         도메인 단위 모듈
│       ├── components/       공용 컴포넌트
│       ├── lib/              apiClient 등 공용 유틸
│       └── mocks/            MSW 핸들러
├── e2e/                      Playwright E2E
├── assets/docker/            Dockerfile / compose
├── scripts/                  start/stop/validate-env 등
├── .env.<env>.example        환경별 변수 (실 값은 .env.<env>)
└── docs/                     문서 카탈로그
```

## 코드 스타일

- Python: ruff + mypy (`ruff check . && mypy .`)
- TS/TSX: eslint + prettier (`npm run lint && npm run format`)
- 커밋 전 자동 실행: `pre-commit install`

## 새 기능 추가 워크플로

1. **RED** — 실패 테스트부터 작성 (`{{backend_dir}}/tests/unit/...` 또는 `{{frontend_dir}}/src/features/.../*.test.tsx`).
2. **GREEN** — 최소 코드로 통과.
3. **REFACTOR** — 정리 후 전체 테스트 재실행.
4. 커밋 — `pre-commit`이 lint/test/secrets를 자동 점검.

## 환경 변수

- 모든 변수는 프로젝트 루트의 `.env.<env>`에 일원화.
- 백엔드: `pydantic-settings`가 `ENVIRONMENT` 기준으로 자동 로드.
- 프론트: Vite `envDir`이 루트를 가리킴 — 변수는 `VITE_` 접두 필수.
- Docker Compose: `env_file: .env.<env>`로 동일 파일 공유.

자세한 내용은 [ENV_SETUP.md](ENV_SETUP.md).
