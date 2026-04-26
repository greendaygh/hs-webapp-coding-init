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

## 백업 / 복원

이 패키지는 백업/복원의 **자리(스크립트 짝)** 만 제공합니다. 보관 기간, 회전 주기,
오프사이트 복제, 암호화, 알림, 스케줄링 같은 **정책은 앱마다 다르므로** 강제하지
않습니다. 운영 시작 전 아래 체크리스트를 채우고 `RUNBOOK.md`(또는 본 문서)에 박제하세요.

### 제공되는 자산

| 스크립트 | 용도 |
| --- | --- |
| `scripts/backup-prod-db.sh` | `mongodump --archive --gzip` → `{{prod_backup_dir}}/<UTC_TS>/dump.archive` |
| `scripts/restore-prod-db.sh` | 위 산출물을 `mongorestore --archive --gzip --drop`으로 되돌림 |

### 사용 예시

```bash
# 백업 (수동/cron 모두 동일)
make backup

# 복원 (대상 디렉터리 지정 필수)
make restore TS={{prod_backup_dir}}/20260426T091500Z

# CI/cron 등 비대화 환경
make restore TS={{prod_backup_dir}}/20260426T091500Z YES=1
```

> 경고: `restore`는 `mongorestore --drop`으로 기존 컬렉션을 삭제한 뒤 복원합니다.
> 운영 DB 직접 실행 전 staging 에서 리허설하세요.

### 백업 정책 결정 체크리스트

아래 항목은 패키지가 정해 주지 않습니다. 운영 시작 전 모두 결정하고 문서로 남기세요.

- [ ] **RPO** (허용 가능한 데이터 손실 시간) — 정해지지 않으면 `mongodump` 1일 1회 = RPO 24h.
- [ ] **RTO** (목표 복구 시간) — 백업 크기와 네트워크/디스크 속도에 의존. 분기 1회 측정 권장.
- [ ] **보관 기간 / 회전 정책** — 예: 일 7 / 주 4 / 월 12. 미설정 시 `{{prod_backup_dir}}` 디스크가 무한히 증가합니다. `find {{prod_backup_dir}} -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec rm -rf {} +` 같은 한 줄을 cron 에 추가하면 14일 회전이 됩니다.
- [ ] **오프사이트 복제** — 본 패키지 미포함. 동일 호스트만 갖고 있으면 단일 장애점입니다. `rclone copy {{prod_backup_dir}} remote:bucket/`, `aws s3 sync`, `rsync` 중 하나를 백업 직후 hook으로 추가하세요. **3-2-1 룰** (사본 3, 매체 2, 오프사이트 1) 권장.
- [ ] **암호화** — 규제 산업(의료/금융)은 필수. `gpg --symmetric` / `age` / 클라우드 KMS 중 택1 후 backup 스크립트 wrapper에서 적용.
- [ ] **무결성 검증** — 단순 `sha256sum dump.archive > dump.archive.sha256` 한 줄을 backup wrapper에서 추가하면 충분한 경우가 많음.
- [ ] **스케줄링** — 호스트 cron, systemd timer, GitHub Actions schedule 중 택1. 호스트 cron 예시:
      `0 3 * * * cd /srv/{{project_slug}} && bash scripts/backup-prod-db.sh >> backups/cron.log 2>&1`
- [ ] **실패 알림** — 위 cron 라인은 실패해도 조용히 묻힙니다. Slack webhook / 이메일 / 모니터링 시스템 연동을 추가하세요.
- [ ] **정기 복원 리허설** — 분기 1회 권장. staging 에 prod 백업을 `make restore TS=... YES=1` 로 복원해 동작 확인. **복원해 본 적 없는 백업은 백업이 아닙니다.**

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

### OIDC 시크릿 체크리스트

OIDC 소셜 로그인 자산이 기본 포함되어 있어, **production/staging 양쪽**에 다음 항목이
설정되어 있어야 정상 기동합니다. (`validate-env.sh` 가 일부를 강제 검증.)

| 변수 | 결정 / 생성 방법 |
| --- | --- |
| `SESSION_SECRET` | `openssl rand -hex 32` (32바이트 이상). 환경마다 다른 값. |
| `SESSION_TTL_HOURS` | 정책 결정 사항 (기본 24). 짧을수록 안전, 길수록 UX 편함. |
| `OIDC_REDIRECT_BASE` | **반드시 HTTPS** 의 외부 노출 도메인. e.g. `https://{{proxy_domain}}`. |
| `OIDC_POST_LOGIN_REDIRECT` | 로그인 성공 후 SPA 진입점. 보통 `OIDC_REDIRECT_BASE` 와 동일 + `/`. |
| `OIDC_MOCK_ENABLED` | production/staging 에선 **반드시 `false`**. `true` 면 startup fail-fast. |
| `OIDC_GOOGLE_CLIENT_ID` / `_SECRET` | Google Cloud Console → OAuth Web client. Authorized redirect URI 에 `${OIDC_REDIRECT_BASE}/auth/callback/google` 추가. |
| `OIDC_GITHUB_CLIENT_ID` / `_SECRET` | (옵션) GitHub Developer settings → OAuth App. Callback URL 에 `${OIDC_REDIRECT_BASE}/auth/callback/github`. |

전체 등록 절차/보안 체크리스트는 [AUTH.md](AUTH.md) 참조.

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
