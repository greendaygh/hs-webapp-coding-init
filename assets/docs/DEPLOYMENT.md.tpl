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
- (v0.2) `deploy-staging.yml`, `deploy-production.yml` — 태그 푸시 시 SSH 배포
