# {{project_name}}

**버전 0.1.0** · {{description}}

## Quick Start

```bash
cp .env.development.example .env.development
bash scripts/start-dev.sh         # DB(docker) + backend + frontend
```

- Frontend: <http://localhost:{{frontend_dev_port}}>
- Backend:  <http://localhost:{{backend_dev_port}}{{health_endpoint}}>
- API docs: <http://localhost:{{backend_dev_port}}/docs>

## 주요 명령어

| 명령어 | 설명 |
| --- | --- |
| `bash scripts/start-dev.sh` | 개발 모드 시작 (DB+API+UI) |
| `bash scripts/stop-dev.sh` | 개발 모드 종료 |
| `bash scripts/start-db.sh` | DB만 docker로 기동 |
| `bash scripts/test-all.sh` | 백엔드+프론트(+E2E) 테스트 |
| `bash scripts/validate-env.sh production` | env 검증 |
| `bash scripts/backup-prod-db.sh` | 프로덕션 DB 백업 |

## 문서 카탈로그

- [GETTING_STARTED.md](docs/GETTING_STARTED.md) — init 직후 첫 30분
- [DEVELOPMENT.md](docs/DEVELOPMENT.md) — 개발 워크플로
- [TESTING.md](docs/TESTING.md) — TDD / 테스트 전략
- [DEPLOYMENT.md](docs/DEPLOYMENT.md) — 스테이징/프로덕션 배포
- [ENV_SETUP.md](docs/ENV_SETUP.md) — 환경 변수 일원화 가이드
- [HARNESS.md](docs/HARNESS.md) — 하네스 엔지니어링

## License

{{license_spdx}} © {{current_year}} {{author}}
