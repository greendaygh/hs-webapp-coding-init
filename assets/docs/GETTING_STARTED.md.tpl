# Getting Started — {{project_name}}

`hs-webapp-coding-init init` 실행 직후 첫 30분 동안 따라할 가이드입니다. 모든 명령은 **Makefile** 단일 진입점으로 통일되어 있습니다.

## 0. 의존 도구

- Docker / Docker Compose v2
- Node {{node_version}}, Python {{python_version}} (`.tool-versions`로 asdf/mise가 자동 인식)
- (선택) `make`, `git`, `gh`

`asdf`/`mise` 사용자는 프로젝트 루트에서 `asdf install` 한 번이면 버전 일치.

## 1. env 복사

```bash
cp .env.development.example .env.development
# 필요 시 .env.staging, .env.production 도 동일하게 복사
```

## 2. 의존성 설치

```bash
make install
```

backend(pip/poetry/conda 자동 감지) + frontend(npm ci) 의존성을 한 번에 설치합니다.

## 3. DB 띄우기

```bash
make db
```

Mongo + Redis 컨테이너가 docker로 기동됩니다. 데이터는 `data/` 디렉터리에 영속화되어 컨테이너를 재시작해도 유지됩니다.

## 4. 첫 테스트 실행 (TDD 1일차)

```bash
make test
```

backend(`pytest`) + frontend(`vitest`)가 모두 통과해야 합니다. 통과하지 않으면 환경 설정 문제이므로 다음 단계 전에 해결하세요.

## 5. 개발 서버 시작

```bash
make dev
```

- Frontend: <http://localhost:{{frontend_dev_port}}>
- Backend health(live): <http://localhost:{{backend_dev_port}}{{health_endpoint}}/live>
- Backend API docs: <http://localhost:{{backend_dev_port}}/docs>

## 6. (선택) Staging 스택 시도

production 발급으로 가기 전에 **Let's Encrypt staging CA**(인증서가 브라우저에 untrusted, 발급 rate-limit 없음)로 리허설할 수 있습니다.

```bash
cp .env.staging.example .env.staging
# CHANGE_ME 값들을 실 값으로 갱신
make validate            # CHANGE_ME가 남아 있으면 fail-fast
make staging             # https://staging.{{proxy_domain}}:{{staging_port}}
make staging-stop        # 종료
```

> staging은 `acme-staging-v02` CA를 사용합니다. 브라우저 경고는 정상이며, 인증서 자동화/Caddy 설정/배포 스크립트의 정합성을 검증하는 용도입니다.

## 7. 보안/품질 점검

```bash
make lint                # ruff + prettier + eslint
make typecheck           # mypy + tsc
make audit               # pip-audit + npm audit (CVE)
make security            # bandit (Python SAST)
```

push/PR 시 GitHub Actions의 `security.yml`이 동일 검사를 자동 수행합니다(gitleaks 추가).

## 다음 단계

- [TESTING.md](TESTING.md) — TDD 사이클로 첫 기능 추가
- [DEVELOPMENT.md](DEVELOPMENT.md) — 디렉터리 구조 / 코드 스타일
- [ARCHITECTURE.md](ARCHITECTURE.md) — DDD 4층 / features 구조 / 배포 토폴로지
- [CONTRIBUTING.md](CONTRIBUTING.md) — TDD 사이클 / PR 가이드
- [HARNESS.md](HARNESS.md) — 하네스 엔지니어링 적용
- [DEPLOYMENT.md](DEPLOYMENT.md) — 스테이징/프로덕션 배포 + CI/CD 시크릿
