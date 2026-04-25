name: {{project_slug}}
channels:
  - conda-forge
dependencies:
  - python={{python_version}}
  - pip
  - pip:
      - fastapi>=0.115
      - "uvicorn[standard]>=0.32"
      - pydantic>=2.9
      - pydantic-settings>=2.5
      - motor>=3.5
      - httpx>=0.27
      - pytest>=8.3
      - pytest-asyncio>=0.24
      - pytest-cov>=5.0
      - ruff>=0.6.9
      - mypy>=1.11
      - factory-boy>=3.3
      - faker>=30.0
