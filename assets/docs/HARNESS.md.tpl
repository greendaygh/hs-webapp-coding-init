# Harness Engineering — {{project_name}}

> *Harness*: 개발/테스트/배포를 **반복 가능하게** 묶어주는 자동화 골격.

본 프로젝트는 다음 하네스를 기본으로 갖춥니다:

| 하네스 | 구성 자산 | 목적 |
| --- | --- | --- |
| **Dev** | `start-dev.sh`, `docker-compose.db-only.yml`, `Makefile`(`make dev`/`make db`) | 한 명령으로 풀스택 기동 |
| **Test** | `pytest.ini`, `vitest.config.ts`, `playwright.config.ts`, MSW, `tests/factories.py` | TDD 사이클 + 데이터 팩토리 |
| **Build/Container** | `Dockerfile.python`, `Dockerfile.node` | 재현 가능한 이미지 |
| **Edge/Proxy** | `Caddyfile.prod`, `Caddyfile.staging` (test-acme) | TLS + 라우팅 단일화, staging 리허설 |
| **Deploy** | `start-prod.sh`, `start-staging.sh`, compose `prod`/`staging`, `deploy-{staging,production}.yml` | 일괄 기동/종료 + SSH CI 배포 |
| **Environment** | `.env.<env>` + `validate-env.sh` (CHANGE_ME fail-fast) | 변수 일원화 + fail-fast |
| **Observability** | `logging_config.py` (dictConfig + Request ID), `/health`, `/health/live`, `/health/ready` (pluggable dependency checks), Frontend `ErrorBoundary` | 가용성/준비성 분리, 로그 컨텍스트 추적 |
| **Data** | bind-mount volumes, `backup-prod-db.sh`, `tests/factories.py`(factory_boy + faker) | 데이터 영속/백업/생성 |
| **Reproducibility** | `.tool-versions` (asdf/mise — Node {{node_version}} / Python {{python_version}}) | 도구 버전 단일 출처 |
| **Security** | `security.yml` (gitleaks + bandit + pip-audit + npm audit, push/PR/weekly), bandit pre-commit, `--allow-exec` opt-in | 시크릿/SAST/CVE 자동 차단 |
| **Onboarding** | `GETTING_STARTED.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, `HARNESS.md`(이 문서), `README.en.md`, `Makefile` | 새 합류자 30분 컷 |

## 사용 패턴

### 1. 매일 아침

```bash
make dev
```

DB 컨테이너가 떠 있으면 재기동하지 않습니다 (멱등). 백/프론트는 host 프로세스로 실행되어 코드 변경 시 자동 리로드.

### 2. 새 기능 작업 (TDD)

1. `make test` — 현재 그린 상태 확인.
2. RED 테스트 작성 → 실패 확인.
3. GREEN 코드 작성 → 통과 확인.
4. `git commit` → pre-commit이 lint/test/secrets/bandit 자동 점검.

### 3. Staging 리허설

```bash
cp .env.staging.example .env.staging   # 실 값으로 갱신
make validate                          # CHANGE_ME fail-fast
make staging                           # test-acme TLS, https://staging.{{proxy_domain}}
```

브라우저 경고는 정상(staging CA). 인증서 자동화/배포 스크립트 정합성 검증용.

### 4. 프로덕션 배포

- 자동(권장): `git tag v0.x.y && git push --tags` → `deploy-production.yml`이 GitHub Environment **production** Required reviewers 승인 후 자동 배포.
- 수동: `make validate && make prod` (서버 위에서).

## 하네스 확장 방법

- 새 의존 서비스(예: PostgreSQL): `docker-compose.db-only.yml`에 service 추가 + `.env.*.example`에 변수 추가 + `validate-env.sh`의 `required` 배열에 추가.
- 새 정적 분석 도구: `precommit/.pre-commit-config.yaml`에 hook 추가 + `security.yml`에 step 추가.
- 새 환경(예: review-app): `.env.review.example` + `docker-compose.review.yml.tpl` + `start-review.sh.tpl` + Caddyfile.review (옵션).
- 새 dependency check(`/health/ready`): `main.py`에서 `register_dependency_check(app, "redis", _ping)` 패턴으로 추가. 검사 실패 시 503 반환.

> 모든 하네스는 **단일 출처(single source of truth)**를 갖습니다. 변수, 도구 버전, 포트 같은 값을 코드 곳곳에 흩뿌리지 마세요. 새 변수는 `.env.*.example` → `validate-env.sh` → `Settings`(config.py) → 사용처 순서로 4곳을 함께 갱신.
