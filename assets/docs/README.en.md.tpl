# {{project_name}}

> {{description}}

> Korean: see [README.md](README.md).

## Quick Start

```bash
cp .env.development.example .env.development
make install        # backend + frontend deps
make db             # start MongoDB + Redis containers
make test           # backend + frontend tests must be green
make dev            # start the full dev stack
```

- Frontend: <http://localhost:{{frontend_dev_port}}>
- Backend health: <http://localhost:{{backend_dev_port}}{{health_endpoint}}>
- API docs: <http://localhost:{{backend_dev_port}}/docs>

## Layout

```
{{backend_dir}}/   FastAPI (DDD: api / application / domain / infrastructure)
{{frontend_dir}}/  React + Vite (features-based)
e2e/               Playwright
assets/docker/     Dockerfiles + docker-compose.{db-only,dev,staging,prod}.yml
scripts/           start/stop-{db,dev,staging,prod}.sh, validate-env.sh, test-all.sh
docs/              GETTING_STARTED, ARCHITECTURE, TESTING, ENV_SETUP, DEPLOYMENT, HARNESS, CONTRIBUTING
.github/workflows/ ci.yml + security.yml + deploy-{staging,production}.yml
.cursor/rules/     TDD + auto-versioning rules
.tool-versions     asdf/mise: nodejs / python pinned
Caddyfile.{prod,staging}
.env.{development,staging,production,test}.example
Makefile           single entry point for all common tasks
```

## Common Make Targets

| Target | Description |
| --- | --- |
| `make help` | List all targets |
| `make install` | Install backend + frontend deps |
| `make db` / `db-stop` | Start / stop database containers |
| `make dev` / `dev-stop` | Start / stop dev stack |
| `make test` | Run backend + frontend tests |
| `make lint` / `typecheck` | Static checks |
| `make audit` / `security` | CVE + SAST scans |
| `make staging` / `staging-stop` | Staging stack (Let's Encrypt **test** CA) |
| `make prod` / `prod-stop` | Production stack |
| `make validate` | Validate `.env.production` / `.env.staging` (`CHANGE_ME` fail-fast) |
| `make backup` | Production DB backup |

## Workflow (TDD)

1. **Red** — write a failing test first.
2. **Green** — the smallest production change that makes it pass.
3. **Refactor** — clean up, keep tests green.

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

## Deployment

- Dev: host processes + DB containers (`make dev`).
- Staging: full Docker stack with Let's Encrypt **staging** CA (browser-untrusted, rate-limit safe).
- Production: full Docker stack with Let's Encrypt **production** CA, behind Caddy.

CI/CD via GitHub Actions:

- `ci.yml` — lint + tests + build on every push/PR.
- `security.yml` — gitleaks + bandit + pip-audit + npm audit (push/PR/weekly).
- `deploy-staging.yml` — `develop` push or `staging-*` tag → SSH rsync + compose up.
- `deploy-production.yml` — `v*` tag → SSH rsync + compose up, gated by `production` GitHub Environment reviewers.

## License

{{license_spdx}} © {{current_year}} {{author}}
