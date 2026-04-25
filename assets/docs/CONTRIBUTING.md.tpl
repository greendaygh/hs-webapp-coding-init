# Contributing — {{project_name}}

이 프로젝트는 **TDD(Red-Green-Refactor)**와 **단일 출처 변수**를 기본으로 합니다.

## 개발 사이클

### 1. 환경 준비

```bash
make install        # backend + frontend 의존성
make db             # DB 컨테이너 기동
make test           # 그린 상태 확인 (TDD 1일차)
```

### 2. 기능 추가 (TDD)

1. **RED** — 실패하는 테스트를 먼저 작성
   - 백엔드: `{{backend_dir}}/tests/unit/<feature>/test_*.py`
   - 프론트: `{{frontend_dir}}/src/features/<feature>/__tests__/*.test.tsx`
   - `make test` → 새 테스트가 빨갛게 실패해야 함.
2. **GREEN** — 테스트를 통과시키는 **최소 코드**만 작성
   - "여기 있는 김에" 식의 추가 구현 금지.
   - `make test` → 그린 확인.
3. **REFACTOR** — 중복 제거, 네이밍 개선
   - 매 변경마다 `make test`로 회귀 확인.

> 한 사이클에서 하나의 동작만 다룹니다. 여러 기능을 한꺼번에 구현하지 마세요.

### 3. 커밋

```bash
git add -p
git commit -m "feat(scope): 무엇을 왜"
```

- pre-commit hook이 자동 실행: ruff(--fix), ruff-format, prettier, eslint, bandit(보안), pytest unit fail-fast.
- 실패 시 fix하고 다시 commit.

### 4. Pull Request

- 브랜치명: `feat/<short-desc>`, `fix/<short-desc>`, `refactor/<short-desc>`.
- PR 본문에 다음을 포함:
  - **Why** (배경/문제)
  - **What** (변경 요약)
  - **How tested** (어떤 시나리오로 검증했는지)
  - **Screenshots** (UI 변경이 있다면)
- CI 그린이어야 머지 가능. 머지 방식은 **Squash and merge** 권장.

## 코드 스타일

- Python: ruff(format + lint) + mypy. `ruff.toml`/`mypy.ini`가 단일 출처.
- TypeScript: Prettier + ESLint. `.prettierrc.json`/`.eslintrc.cjs`가 단일 출처.
- 자동 포매터에 거역하지 마세요. 일관성 > 개인 취향.

## 디렉터리 규칙

- 백엔드: DDD 4층(`api/application/domain/infrastructure`). 의존은 한 방향.
- 프론트: features 단위. 한 feature가 다른 feature를 직접 import 금지.
- 자세한 내용: [ARCHITECTURE.md](ARCHITECTURE.md).

## 환경 변수

- 새 변수 추가 시 다음 4곳을 함께 갱신: `.env.*.example` → `validate-env.sh` `required[]` → `config.py` Settings → 사용처.
- 운영 시크릿(`SECRET_KEY`, DB URI 등)에 `CHANGE_ME` placeholder를 남기면 `validate-env.sh production`이 fail-fast.

## 보안

- 시크릿을 코드/커밋에 절대 포함하지 마세요. gitleaks가 push 시 검출합니다.
- 새 의존성 추가 시 `make audit`로 CVE 점검.
- `--allow-exec` 플래그 없이는 임의 명령 실행 자산이 동작하지 않습니다.

## 문서

- 사용자 가시 변경(기능/UI/명령어)은 README/CHANGELOG/관련 docs 모두 갱신.
- 자세한 변경 → ARCHITECTURE/CONTRIBUTING/HARNESS 중 적합한 곳.
- 단순 버그 수정/내부 리팩터는 CHANGELOG `Fixed`/`Changed` 한 줄로 충분.

## 릴리스

- 커밋/푸시는 [auto-versioning rule](.cursor/rules/auto-versioning.mdc)에 따라 patch/minor/major 자동 결정.
- `v*` 태그 푸시 → `deploy-production.yml` 워크플로 → production Environment 승인 후 배포.
