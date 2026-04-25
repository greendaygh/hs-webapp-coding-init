name: Deploy Staging

on:
  push:
    branches: [develop]
    tags:
      - "staging-*"
  workflow_dispatch:

concurrency:
  group: deploy-staging
  cancel-in-progress: false

permissions:
  contents: read

jobs:
  deploy:
    name: Rsync + docker compose up (staging)
    runs-on: ubuntu-latest
    environment:
      name: staging
    steps:
      - uses: actions/checkout@v4

      - name: Setup SSH key
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.DEPLOY_SSH_KEY }}" > ~/.ssh/id_deploy
          chmod 600 ~/.ssh/id_deploy
          ssh-keyscan -H "${{ secrets.DEPLOY_SSH_HOST }}" >> ~/.ssh/known_hosts

      - name: Rsync sources
        run: |
          rsync -az --delete \
            --exclude '.git' --exclude 'node_modules' --exclude '__pycache__' \
            --exclude '.venv' --exclude 'data/' --exclude 'logs/' \
            -e "ssh -i ~/.ssh/id_deploy -o StrictHostKeyChecking=yes" \
            ./ \
            "${{ secrets.DEPLOY_SSH_USER }}@${{ secrets.DEPLOY_SSH_HOST }}:${{ secrets.DEPLOY_PATH }}/"

      - name: Remote validate-env + compose up
        run: |
          ssh -i ~/.ssh/id_deploy -o StrictHostKeyChecking=yes \
            "${{ secrets.DEPLOY_SSH_USER }}@${{ secrets.DEPLOY_SSH_HOST }}" \
            "cd '${{ secrets.DEPLOY_PATH }}' && \
             bash scripts/validate-env.sh staging && \
             docker compose -f assets/docker/docker-compose.staging.yml --env-file .env.staging up -d --build"

      - name: Smoke test (staging health)
        run: |
          ssh -i ~/.ssh/id_deploy -o StrictHostKeyChecking=yes \
            "${{ secrets.DEPLOY_SSH_USER }}@${{ secrets.DEPLOY_SSH_HOST }}" \
            "curl -fsS -m 10 -o /dev/null --resolve staging.{{proxy_domain}}:443:127.0.0.1 \
              https://staging.{{proxy_domain}}{{health_endpoint}}/live -k || \
             curl -fsS -m 10 http://localhost:{{staging_port}}{{health_endpoint}}/live"
