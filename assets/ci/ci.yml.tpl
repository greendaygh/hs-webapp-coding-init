name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  backend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: {{backend_dir}}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "{{python_version}}"
      - name: Install
        run: |
          python -m pip install --upgrade pip
          if [ -f requirements-dev.txt ]; then pip install -r requirements-dev.txt; fi
          if [ -f pyproject.toml ]; then pip install -e ".[dev]" || pip install . ; fi
      - name: Lint
        run: ruff check .
      - name: Type check
        run: mypy . || true
      - name: Test
        run: pytest -q
        env:
          ENVIRONMENT: test

  frontend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: {{frontend_dir}}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "{{node_version}}"
          cache: npm
          cache-dependency-path: {{frontend_dir}}/package-lock.json
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm run test:run

  build:
    needs: [backend, frontend]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build backend image
        run: docker build -f assets/docker/Dockerfile.python -t {{project_slug}}-backend:ci .
      - name: Build frontend image
        run: docker build -f assets/docker/Dockerfile.node -t {{project_slug}}-frontend:ci .
