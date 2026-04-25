name: {{db_container_prefix}}-staging

services:
  mongodb:
    image: mongo:{{mongodb_version}}
    container_name: {{db_container_prefix}}-mongodb-staging
    restart: unless-stopped
    env_file:
      - .env.staging
    volumes:
      - mongodb_data:/data/db
      - mongodb_config:/data/configdb
    healthcheck:
      test: ["CMD", "mongosh", "--quiet", "--eval", "db.adminCommand('ping').ok"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:{{redis_version}}
    container_name: {{db_container_prefix}}-redis-staging
    restart: unless-stopped
    volumes:
      - redis_data:/data

  backend:
    build:
      context: .
      dockerfile: assets/docker/Dockerfile.python
    container_name: {{db_container_prefix}}-backend-staging
    restart: unless-stopped
    env_file:
      - .env.staging
    environment:
      ENVIRONMENT: staging
    depends_on:
      mongodb:
        condition: service_healthy

  frontend:
    build:
      context: .
      dockerfile: assets/docker/Dockerfile.node
    container_name: {{db_container_prefix}}-frontend-staging
    restart: unless-stopped
    depends_on:
      - backend

  caddy:
    image: caddy:{{caddy_version}}
    container_name: {{db_container_prefix}}-caddy-staging
    restart: unless-stopped
    ports:
      - "{{staging_port}}:80"
      - "{{proxy_https_port}}:443"
    volumes:
      - ./Caddyfile.staging:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - frontend
      - backend

volumes:
  mongodb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: {{prod_data_dir}}/staging/mongodb
  mongodb_config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: {{prod_data_dir}}/staging/mongodb-config
  redis_data:
  caddy_data:
  caddy_config:
