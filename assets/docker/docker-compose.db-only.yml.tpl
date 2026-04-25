name: {{db_container_prefix}}-db

services:
  mongodb:
    image: mongo:{{mongodb_version}}
    container_name: {{db_container_prefix}}-mongodb-dev
    restart: unless-stopped
    env_file:
      - .env.development
    ports:
      - "{{mongodb_host_port_dev}}:27017"
    volumes:
      - {{mongodb_data_dir_dev}}:/data/db
      - {{mongodb_config_dir_dev}}:/data/configdb
    healthcheck:
      test: ["CMD", "mongosh", "--quiet", "--eval", "db.adminCommand('ping').ok"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:{{redis_version}}
    container_name: {{db_container_prefix}}-redis-dev
    restart: unless-stopped
    ports:
      - "{{redis_host_port_dev}}:6379"
    volumes:
      - {{redis_data_dir_dev}}:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
