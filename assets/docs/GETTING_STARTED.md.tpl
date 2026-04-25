# Getting Started — {{project_name}}

`hs-webapp-coding-init init` 실행 직후 첫 30분 동안 따라할 가이드입니다.

## 1. env 복사

```bash
cp .env.development.example .env.development
# 필요 시 .env.staging, .env.production 도 동일하게 복사
```

## 2. DB 띄우기

```bash
bash scripts/start-db.sh
```

Mongo + Redis 컨테이너가 docker로 기동됩니다. 데이터는 `data/` 디렉터리에 영속화되어 컨테이너를 재시작해도 유지됩니다.

## 3. 백엔드 의존성 설치

선택한 패키지 매니저에 따라:

```bash
cd {{backend_dir}}
# pip
pip install -r requirements-dev.txt
# 또는 poetry
poetry install
# 또는 conda
conda env create -f environment.yml && conda activate {{project_slug}}
```

## 4. 프론트엔드 의존성 설치

```bash
cd {{frontend_dir}}
npm ci
```

## 5. 첫 테스트 실행 (TDD 1일차)

```bash
bash scripts/test-all.sh
```

backend(`pytest`) + frontend(`vitest`)가 모두 통과해야 합니다. 통과하지 않으면 환경 설정 문제입니다.

## 6. 개발 서버 시작

```bash
bash scripts/start-dev.sh
```

- Frontend: <http://localhost:{{frontend_dev_port}}>
- Backend health: <http://localhost:{{backend_dev_port}}{{health_endpoint}}>

## 다음 단계

- [TESTING.md](TESTING.md) — TDD 사이클로 첫 기능 추가
- [DEVELOPMENT.md](DEVELOPMENT.md) — 디렉터리 구조 / 코드 스타일
- [HARNESS.md](HARNESS.md) — 하네스 엔지니어링 적용
- [DEPLOYMENT.md](DEPLOYMENT.md) — 스테이징/프로덕션 배포
