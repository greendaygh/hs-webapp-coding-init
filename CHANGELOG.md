# Changelog

이 프로젝트의 모든 주요 변경사항은 이 파일에 기록됩니다. 형식은 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)를 따르고, 버저닝은 [SemVer](https://semver.org/lang/ko/)를 따릅니다.

## [v0.1.0] - 2026-04-25

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
