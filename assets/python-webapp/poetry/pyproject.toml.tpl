[tool.poetry]
name = "{{project_slug}}-backend"
version = "0.1.0"
description = "{{description}}"
authors = ["{{author}}"]
license = "{{license_spdx}}"
readme = "../README.md"
packages = [{ include = "{{app_module}}" }]

[tool.poetry.dependencies]
python = "^{{python_version}}"
fastapi = "^0.115.0"
uvicorn = { extras = ["standard"], version = "^0.32.0" }
pydantic = "^2.9.0"
pydantic-settings = "^2.5.0"
motor = "^3.5.0"
httpx = "^0.27.0"
authlib = "^1.3.0"
itsdangerous = "^2.2.0"

[tool.poetry.group.dev.dependencies]
pytest = "^8.3.0"
pytest-asyncio = "^0.24.0"
pytest-cov = "^5.0.0"
ruff = "^0.6.9"
mypy = "^1.11.0"
factory-boy = "^3.3.0"
faker = "^30.0.0"
bandit = { extras = ["toml"], version = "^1.7" }
pip-audit = "^2.7"
respx = "^0.21.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
