# Harness Engineering — {{project_name}}

> *Harness*: 개발/테스트/배포를 **반복 가능하게** 묶어주는 자동화 골격.

본 프로젝트는 다음 하네스를 기본으로 갖춥니다:

| 하네스 | 구성 자산 | 목적 |
| --- | --- | --- |
| **Dev** | `start-dev.sh`, `docker-compose.db-only.yml` | 한 명령으로 풀스택 기동 |
| **Test** | `pytest.ini`, `vitest.config.ts`, `playwright.config.ts`, MSW | TDD 사이클 |
| **Build/Container** | `Dockerfile.python`, `Dockerfile.node` | 재현 가능한 이미지 |
| **Edge/Proxy** | `Caddyfile.prod` | TLS + 라우팅 단일화 |
| **Deploy** | `start-prod.sh`, compose prod | 일괄 기동/종료 |
| **Environment** | `.env.<env>` + `validate-env.sh` | 변수 일원화 + fail-fast |
| **Observability** | `/health`, `/health/live`, `/health/ready` | 가용성/준비성 분리 |
| **Data** | bind-mount volumes, `backup-prod-db.sh` | 데이터 영속/백업 |
| **Reproducibility** | `.tool-versions` (선택) | 도구 버전 일치 |
| **Onboarding** | `GETTING_STARTED.md`, `HARNESS.md` (이 문서) | 새 합류자 30분 |

## 사용 패턴

### 1. 매일 아침

```bash
bash scripts/start-dev.sh
```

DB 컨테이너가 떠 있으면 재기동하지 않습니다 (멱등). 백/프론트는 host 프로세스로 실행되어 코드 변경 시 자동 리로드.

### 2. 새 기능 작업

1. `bash scripts/test-all.sh` — 현재 그린 상태 확인
2. RED 테스트 작성 → 실패 확인
3. GREEN 코드 작성 → 통과 확인
4. `git commit` → pre-commit이 lint/test/secrets 자동 점검

### 3. 프로덕션 배포

1. `bash scripts/validate-env.sh production` — 변수/시크릿 점검
2. `git pull && bash scripts/start-prod.sh` — 빌드+기동
3. Caddy가 자동 TLS, healthcheck 통과 후 트래픽 전환

## 하네스 확장 방법

- 새 의존 서비스(예: PostgreSQL): `docker-compose.db-only.yml`에 service 추가 + `.env.*.example`에 변수 추가 + `validate-env.sh`의 `required` 배열에 추가.
- 새 정적 분석 도구: `precommit/.pre-commit-config.yaml`에 hook 추가 + CI workflow에 step 추가.
- 새 환경(예: review-app): `.env.review.example` + `docker-compose.review.yml.tpl` + `start-review.sh.tpl` 세트 추가.

> 모든 하네스는 **단일 출처(single source of truth)**를 갖습니다. 변수, 도구 버전, 포트 같은 값을 코드 곳곳에 흩뿌리지 마세요.
