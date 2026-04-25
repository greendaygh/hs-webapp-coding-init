# Testing — {{project_name}}

본 프로젝트는 **TDD(Red-Green-Refactor)** 사이클을 따릅니다.

## 테스트 계층

| 계층 | 도구 | 위치 | 비고 |
| --- | --- | --- | --- |
| Unit (backend) | pytest | `{{backend_dir}}/tests/unit` | 빠른 실행, 외부 의존 없음 |
| Integration (backend) | pytest | `{{backend_dir}}/tests/integration` | DB/외부 컨테이너 필요 |
| Unit (frontend) | vitest + RTL | `{{frontend_dir}}/src/**/*.test.tsx` | MSW로 API mock |
| E2E | Playwright | `e2e/tests/*.spec.ts` | 실제 브라우저 |

## 빠른 명령어

```bash
# 통합 실행 (backend + frontend + e2e if present)
bash scripts/test-all.sh

# 백엔드만 (커버리지 임계치 {{coverage_threshold}}% 자동 체크)
cd {{backend_dir}} && pytest -q

# 프론트만
cd {{frontend_dir}} && npm run test:run

# E2E (서버가 떠 있어야 함)
cd e2e && npm test
```

## TDD 1일차 가이드

`init` 직후 다음이 통과합니다:

- `tests/unit/test_health.py` — health/live/ready 3개
- `src/App.test.tsx` — App 렌더 + MSW health mock 통과

이 중 **1개를 일부러 깨뜨려서 RED 색상을 확인**하고 다시 복구하세요. TDD 사이클을 몸으로 익히는 가장 빠른 방법입니다.

## MSW (Mock Service Worker)

프론트의 모든 API 호출은 테스트 환경에서 `src/mocks/handlers.ts`의 응답으로 가로챕니다. 새 API를 추가할 때는 핸들러도 함께 작성하세요.

## 커버리지 정책

- backend: `pytest.ini`의 `--cov-fail-under={{coverage_threshold}}`
- frontend: `vitest.config.ts`의 `coverage.thresholds`
- 새 코드 PR은 커버리지를 떨어뜨리지 않도록 합니다.
