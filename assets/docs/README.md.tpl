# {{project_name}}

**버전 0.1.0** · {{description}}

> English: see [README.en.md](README.en.md).

## Quick Start

```bash
cp .env.development.example .env.development
make install                      # backend + frontend 의존성
make db                           # DB 컨테이너 기동
make test                         # backend + frontend 테스트가 그린이어야 함
make dev                          # 풀스택 개발 모드
```

- Frontend: <http://localhost:{{frontend_dev_port}}>
- Backend: <http://localhost:{{backend_dev_port}}{{health_endpoint}}>
- API docs: <http://localhost:{{backend_dev_port}}/docs>

## 주요 명령어 (Makefile)

`make help`로 모든 타겟을 확인할 수 있습니다.

| 명령어 | 설명 |
| --- | --- |
| `make dev` / `make dev-stop` | 개발 모드 시작/종료 |
| `make db` / `make db-stop` | DB만 기동/종료 |
| `make test` | backend + frontend 테스트 |
| `make lint` / `make typecheck` | 정적 검사 |
| `make audit` / `make security` | CVE + SAST 검사 |
| `make staging` / `make staging-stop` | Staging 스택 (test-acme TLS) |
| `make prod` / `make prod-stop` | Production 스택 |
| `make validate` | `.env.production`/`.env.staging` 검증 (CHANGE_ME fail-fast) |
| `make backup` | Production DB 백업 |

## 문서 카탈로그

- [GETTING_STARTED.md](docs/GETTING_STARTED.md) — init 직후 첫 30분
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — DDD 4층 / features 구조 / 배포 토폴로지
- [DEVELOPMENT.md](docs/DEVELOPMENT.md) — 개발 워크플로
- [TESTING.md](docs/TESTING.md) — TDD / 테스트 전략
- [CONTRIBUTING.md](docs/CONTRIBUTING.md) — 기여/PR 가이드
- [DEPLOYMENT.md](docs/DEPLOYMENT.md) — 스테이징/프로덕션 배포 + CI/CD 시크릿
- [ENV_SETUP.md](docs/ENV_SETUP.md) — 환경 변수 일원화 가이드
- [HARNESS.md](docs/HARNESS.md) — 하네스 엔지니어링

## License

{{license_spdx}} © {{current_year}} {{author}}
