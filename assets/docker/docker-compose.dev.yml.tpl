name: {{db_container_prefix}}-dev

services:
  mongodb:
    extends:
      file: docker-compose.db-only.yml
      service: mongodb

  redis:
    extends:
      file: docker-compose.db-only.yml
      service: redis

  backend:
    build:
      context: .
      dockerfile: assets/docker/Dockerfile.python
    container_name: {{db_container_prefix}}-backend-dev
    env_file:
      - .env.development
    environment:
      ENVIRONMENT: development
    ports:
      - "{{backend_dev_port}}:{{backend_dev_port}}"
    depends_on:
      mongodb:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./{{backend_dir}}:/app
    command: ["uvicorn", "{{app_module}}.main:app", "--host", "0.0.0.0", "--port", "{{backend_dev_port}}", "--reload"]
