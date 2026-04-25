ARG PYTHON_VERSION={{python_version}}
FROM python:${PYTHON_VERSION}-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential curl \
    && rm -rf /var/lib/apt/lists/*

# requirements 우선 (캐시 활용)
COPY {{backend_dir}}/requirements*.txt ./
RUN pip install -r requirements.txt

COPY {{backend_dir}}/ /app/

EXPOSE {{backend_dev_port}}

CMD ["uvicorn", "{{app_module}}.main:app", "--host", "0.0.0.0", "--port", "{{backend_dev_port}}"]
