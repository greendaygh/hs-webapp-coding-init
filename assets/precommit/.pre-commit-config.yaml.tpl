repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
        args: ["--maxkb=1024"]

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.9
    hooks:
      - id: ruff
        args: ["--fix"]
      - id: ruff-format

  - repo: https://github.com/PyCQA/bandit
    rev: "1.7.10"
    hooks:
      - id: bandit
        name: bandit (security lint, backend only)
        args: ["-q", "-ll", "-ii", "-x", "tests"]
        files: ^{{backend_dir}}/{{app_module}}/.*\.py$

  - repo: local
    hooks:
      - id: pytest-quick
        name: pytest (unit, fail-fast)
        entry: bash -c 'cd {{backend_dir}} && pytest tests/unit -x -q --no-cov'
        language: system
        pass_filenames: false
        types: [python]
        stages: [commit]

      - id: lint-staged-frontend
        name: lint-staged (frontend)
        entry: bash -c 'cd {{frontend_dir}} && npx lint-staged'
        language: system
        pass_filenames: false
        types_or: [ts, tsx, javascript, jsx]
        stages: [commit]
