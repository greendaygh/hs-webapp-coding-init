name: Security

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  schedule:
    # 매주 월요일 03:00 UTC (KST 12:00) 정기 스캔
    - cron: "0 3 * * 1"

permissions:
  contents: read
  security-events: write

jobs:
  gitleaks:
    name: Gitleaks (secret scan)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Run gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  bandit:
    name: Bandit (Python SAST)
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: {{backend_dir}}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "{{python_version}}"
      - name: Install bandit
        run: |
          python -m pip install --upgrade pip
          pip install "bandit[toml]>=1.7"
      - name: Run bandit
        run: |
          bandit -r {{app_module}} -ll -ii \
            --exclude tests \
            --format txt

  pip-audit:
    name: pip-audit (Python deps CVE)
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: {{backend_dir}}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "{{python_version}}"
      - name: Install pip-audit
        run: |
          python -m pip install --upgrade pip
          pip install pip-audit
      - name: Audit
        run: |
          if [ -f requirements.txt ]; then
            pip-audit -r requirements.txt --strict || exit 1
          elif [ -f pyproject.toml ]; then
            pip-audit . --strict || exit 1
          else
            echo "no python deps file found, skipping"
          fi

  npm-audit:
    name: npm audit (Node deps CVE)
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
      - name: Run npm audit (high+ as blocking)
        run: npm audit --audit-level=high
