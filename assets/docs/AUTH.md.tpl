# Auth Harness — {{project_name}}

OIDC/OAuth2 소셜 로그인을 표준 자산으로 제공합니다. 비밀번호 저장은 IdP(Google, GitHub 등)에 위임하고, 백엔드는 콜백 후 **HTTP-only 서명 쿠키 기반 서버 세션**을 발급해 SPA가 그대로 활용합니다.

## 1. 흐름

```mermaid
flowchart LR
    user["browser"] -->|"GET /auth/login/google"| be["FastAPI"]
    be -->|"302 redirect"| google["Google OIDC"]
    google -->|"code callback"| be2["FastAPI /auth/callback/google"]
    be2 -->|"upsert"| users[("MongoDB users")]
    be2 -->|"insert"| sessions[("MongoDB sessions")]
    be2 -->|"Set-Cookie sid"| user
    user -->|"GET /auth/me (cookie)"| be3["FastAPI"]
    be3 -->|"lookup"| sessions
    be3 -->|"User"| user

    devUser["dev only"] -->|"GET /auth/login/mock?email=..."| be4["FastAPI (OIDC_MOCK_ENABLED=true)"]
    be4 -->|"shortcut"| sessions
```

## 2. 1분 컷 (dev)

```bash
make dev
# http://localhost:{{frontend_dev_port}}/login → email 입력 → "Mock 로그인 (dev)"
# 보호 페이지(/) 진입 + 헤더에 사용자 메뉴
```

`OIDC_MOCK_ENABLED=true` 일 때만 동작합니다. staging/production 에서 `true` 면 `validate-env.sh` 와 백엔드 startup 양쪽에서 fail-fast.

## 3. Provider 등록 walkthrough

### Google

1. [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials → **Create Credentials → OAuth client ID** → Web application.
2. **Authorized redirect URIs** 에 환경별 콜백 URL 추가:
   - dev: `http://localhost:{{backend_dev_port}}/auth/callback/google`
   - staging: `https://staging.{{proxy_domain}}/auth/callback/google`
   - production: `https://{{proxy_domain}}/auth/callback/google`
3. `OIDC_GOOGLE_CLIENT_ID`, `OIDC_GOOGLE_CLIENT_SECRET` 환경변수 입력.
4. `bash scripts/validate-env.sh <env>` 통과 확인 → 재기동.

### GitHub (옵션)

1. [GitHub Developer settings](https://github.com/settings/developers) → New OAuth App.
2. **Authorization callback URL** 에 콜백 URL 입력 (`/auth/callback/github`).
3. `OIDC_GITHUB_CLIENT_ID`, `OIDC_GITHUB_CLIENT_SECRET` 입력.

### 새 IdP 추가 패턴

`infrastructure/oidc_clients.py` 의 `build_oauth()` 에 한 줄 추가:

```python
oauth.register(
    name="azure",
    client_id=settings.oidc_azure_client_id,
    client_secret=settings.oidc_azure_client_secret,
    server_metadata_url=f"https://login.microsoftonline.com/{tenant}/v2.0/.well-known/openid-configuration",
    client_kwargs={"scope": "openid email profile"},
)
```

`Settings`(`config.py`) + `.env.*.example.tpl` 4종 + `LoginButton.tsx` 라벨까지 SSOT 4단계로 동시 갱신하면 끝. ([CONTRIBUTING.md](CONTRIBUTING.md) "새 환경변수 4단계 체크리스트" 참고)

## 4. 세션 / 쿠키 / CSRF

- **세션 쿠키**: 이름 `sid` (변경 가능: `SESSION_COOKIE_NAME`), `HttpOnly`, `Secure` (production), `SameSite=Lax`, `path=/`.
- **TTL**: `SESSION_TTL_HOURS` (기본 24h). MongoDB `sessions` 컬렉션의 `expires_at` 에 TTL 인덱스가 걸려 자동 만료.
- **로그아웃**: `POST /auth/logout` → 세션 doc 삭제 + `sid` 쿠키 만료.
- **CSRF**: `SameSite=Lax` 로 GET 외 cross-site 요청에서 쿠키 미전송. 추가 토큰이 필요하면 `fastapi-csrf-protect` 같은 라이브러리를 도입하세요 (본 패키지 비범위).
- **OIDC state**: `SessionMiddleware`(`itsdangerous` 서명) 가 인가 흐름 중 임시 state 를 보관. `SESSION_SECRET` 이 동일하면 두 가지 모두 안전.

## 5. 보안 체크리스트

- [ ] `SESSION_SECRET` 은 `openssl rand -hex 32` 으로 생성한 32바이트 이상.
- [ ] production/staging 의 `OIDC_REDIRECT_BASE` 는 반드시 HTTPS.
- [ ] production/staging 에서 `OIDC_MOCK_ENABLED=false`. (`validate-env.sh` + main.py startup 양쪽 가드)
- [ ] OIDC redirect URI 가 IdP 콘솔에 정확히 등록되어 있는지(말미 슬래시까지) 확인.
- [ ] 시크릿은 GitHub Secrets / 서버 환경변수로만 주입. `.env.production` 은 git 무시.
- [ ] 쿠키 도메인이 의도한 호스트로 한정되는지(`Caddyfile` host header 통과) 확인.

## 6. 자주 묻는 질문

**Q. JWT/refresh token 을 쓰고 싶다.**
A. 본 패키지는 의도적으로 쿠키 세션만 제공합니다. 쿠키 → MongoDB 룩업이 단순하고 즉시 폐기 가능합니다. JWT 가 필요하면 `infrastructure/session_repo.py` 만 교체하거나 `/auth/token` 엔드포인트를 별도 추가하는 형태로 확장하세요.

**Q. Redis 세션 스토어로 바꾸고 싶다.**
A. `application/auth_service.py` 가 `SessionRepo` Protocol 에만 의존합니다. `infrastructure/session_repo.py` 를 Redis 구현으로 교체하면 끝.

**Q. MongoDB 외 DB 를 쓴다.**
A. `db_kind=mongodb` 가 default 이며 다른 DB 는 정식 지원 안 됩니다. `user_repo.py` / `session_repo.py` 두 파일을 사용 DB 에 맞게 다시 구현하세요.

**Q. 회원가입 폼 / 이메일 인증 / 비밀번호 재설정이 필요하다.**
A. OIDC 사용 시 IdP 가 처리합니다. 자체 폼이 필요하면 별도 자산으로 추가하시되, 본 패키지의 OIDC 흐름과 직교 설계하세요.

## 7. SSOT 매트릭스 (회귀 방지)

새 변수 4곳 SSOT 준수:

| 변수 | env 4종 | validate-env | Settings | 사용처 |
| --- | :-: | :-: | :-: | :-: |
| `SESSION_SECRET` | ✓ | required + CHANGE_ME | ✓ | `SessionMiddleware`, `auth.py` 쿠키 서명 |
| `SESSION_TTL_HOURS` | ✓ | – | ✓ | `auth_service.create_session` |
| `OIDC_REDIRECT_BASE` | ✓ | – | ✓ | `oidc_clients.py`, `auth.py` callback |
| `OIDC_MOCK_ENABLED` | ✓ | prod/staging guard | ✓ | `main.py` startup, `auth.py` mock 라우트 |
| `OIDC_GOOGLE_CLIENT_ID/SECRET` | ✓ | – | ✓ | `oidc_clients.build_oauth` |
| `OIDC_GITHUB_CLIENT_ID/SECRET` | ✓ | – | ✓ | `oidc_clients.build_oauth` |
