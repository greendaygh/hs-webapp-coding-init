[project]
name = "{{project_slug}}-backend"
version = "0.1.0"
description = "{{description}}"
readme = "../README.md"
requires-python = ">={{python_version}}"
license = { text = "{{license_spdx}}" }
authors = [{ name = "{{author}}" }]
dependencies = [
  "fastapi>=0.115",
  "uvicorn[standard]>=0.32",
  "pydantic>=2.9",
  "pydantic-settings>=2.5",
  "motor>=3.5",
  "httpx>=0.27",
]

[project.optional-dependencies]
dev = [
  "pytest>=8.3",
  "pytest-asyncio>=0.24",
  "pytest-cov>=5.0",
  "ruff>=0.6.9",
  "mypy>=1.11",
]

[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
include = ["{{app_module}}*"]
