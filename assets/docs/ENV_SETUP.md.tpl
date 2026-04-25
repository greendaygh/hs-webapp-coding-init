# Environment Variables — {{project_name}}

모든 환경 변수는 **프로젝트 루트의 `.env.<env>` 파일 하나**로 일원화합니다.

## 파일

| 파일 | 사용처 | 커밋 |
| --- | --- | --- |
| `.env.development` | 로컬 개발 | ✗ |
| `.env.staging` | 스테이징 (선택) | ✗ |
| `.env.production` | 프로덕션 | ✗ |
| `.env.test` | CI / 로컬 테스트 | ✗ |
| `.env.*.example` | 템플릿 | ✓ |

> 실제 비밀값이 들어 있는 `.env.*` 파일은 커밋하지 않습니다 (`.gitignore`로 차단).

## 일원화 메커니즘

- **백엔드(Pydantic Settings)**: `{{app_module}}/config.py`가 `ENVIRONMENT` 변수로 `.env.<env>`를 자동 선택합니다.
- **프론트(Vite)**: `vite.config.ts`의 `envDir`이 프로젝트 루트로 설정되어, `VITE_*` 접두가 붙은 변수만 클라이언트 번들에 포함됩니다.
- **Docker Compose**: 각 서비스에 `env_file: .env.<env>`를 명시.

## 검증

운영 환경에서는 시작 전에 반드시 검증하세요:

```bash
bash scripts/validate-env.sh production
```

- 필수 변수 누락 → exit 2
- `CHANGE_ME` placeholder 잔존 (staging/production) → exit 3

## 비밀 관리 권장

- 로컬: `.env.<env>` (커밋 금지)
- CI: GitHub Actions `secrets.*`
- 프로덕션 서버: SOPS / Vault / 1Password CLI 등으로 주입
