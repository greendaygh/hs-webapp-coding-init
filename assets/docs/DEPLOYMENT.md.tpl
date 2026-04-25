# Deployment — {{project_name}}

## 환경

| 환경 | URL | Compose 파일 | 시작 스크립트 |
| --- | --- | --- | --- |
| development | localhost | `docker-compose.dev.yml` | `start-dev.sh` |
| staging (opt) | staging.{{proxy_domain}} | `docker-compose.staging.yml` | `start-staging.sh` |
| production | {{proxy_domain}} | `docker-compose.prod.yml` | `start-prod.sh` |

## 프로덕션 첫 배포

```bash
ssh user@{{proxy_domain}}
git clone <repo> {{project_slug}}
cd {{project_slug}}

cp .env.production.example .env.production
# .env.production을 편집하여 SECRET_KEY, MONGODB_URI, ACME_EMAIL 등을 실 값으로

bash scripts/validate-env.sh production
bash scripts/start-prod.sh
```

Caddy가 자동으로 Let's Encrypt 인증서를 발급하고 HTTPS로 서비스합니다.

## 데이터 영속성

- 프로덕션 DB는 `{{prod_data_dir}}/mongodb`에 bind mount.
- 컨테이너 재시작/재빌드 후에도 데이터 유지.
- 정기 백업: `bash scripts/backup-prod-db.sh` (cron 권장).

## 무중단 업데이트

```bash
git pull
docker compose -f assets/docker/docker-compose.prod.yml --env-file .env.production up -d --build
```

healthcheck가 통과해야 새 컨테이너로 트래픽이 전환됩니다.

## CI/CD

- `.github/workflows/ci.yml` — 모든 PR/푸시에서 lint + test + build
- `.github/workflows/security.yml` — gitleaks + bandit + pip-audit + npm audit (push/PR/매주)
- `.github/workflows/deploy-staging.yml` — `develop` 브랜치 푸시 또는 `staging-*` 태그에서 SSH 배포
- `.github/workflows/deploy-production.yml` — `v*` 태그 푸시 또는 수동 실행에서 SSH 배포 (`production` Environment 수동 승인 게이트)

## Deploy 시크릿 체크리스트

GitHub Repository → **Settings** → **Secrets and variables** → **Actions** → **Repository secrets** 에 아래 4개를 등록합니다.

| Secret 이름 | 예시 / 설명 |
| --- | --- |
| `DEPLOY_SSH_HOST` | `{{proxy_domain}}` 또는 IP. ssh-keyscan 대상이 됨. |
| `DEPLOY_SSH_USER` | 배포 전용 OS 사용자 (sudo 없이 docker 가능해야 함, e.g. `deploy`). |
| `DEPLOY_SSH_KEY` | 위 사용자 인증용 **개인 키 전문** (PEM, OpenSSH). 한 줄도 잘리지 않게 그대로 붙여넣기. |
| `DEPLOY_PATH` | 서버 상의 프로젝트 절대 경로 (e.g. `/srv/{{project_slug}}`). 미리 git clone 또는 빈 디렉터리로 준비. |

추가로 `production` 환경에 reviewer를 지정하려면:

1. GitHub → **Settings** → **Environments** → **New environment** → 이름 `production`.
2. **Required reviewers**에 검토자를 추가, 필요 시 **Deployment branches**를 `main` / 태그 패턴으로 제한.
3. `staging` Environment도 동일 방식으로 만들어 둘 수 있습니다 (선택).

서버 사전 준비 (한 번만):

```bash
ssh user@{{proxy_domain}}
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
sudo mkdir -p /srv/{{project_slug}} && sudo chown deploy:deploy /srv/{{project_slug}}
# deploy 사용자 ~/.ssh/authorized_keys에 DEPLOY_SSH_KEY의 공개 키 추가
git clone <repo> /srv/{{project_slug}}
cp .env.production.example .env.production && vim .env.production
bash scripts/validate-env.sh production
```
