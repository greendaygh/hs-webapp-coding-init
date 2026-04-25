name: Deploy Production

on:
  push:
    tags:
      - "v*"
  workflow_dispatch:
    inputs:
      ref:
        description: "Tag or commit SHA to deploy"
        required: true
        default: "main"

concurrency:
  group: deploy-production
  cancel-in-progress: false

permissions:
  contents: read

jobs:
  deploy:
    name: Rsync + docker compose up (production)
    runs-on: ubuntu-latest
    # GitHub Environments → 'production'에 reviewer/branch protection을 걸어 수동 승인 게이트로 활용.
    environment:
      name: production
      url: https://{{proxy_domain}}
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.ref || github.ref }}

      - name: Setup SSH key
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.DEPLOY_SSH_KEY }}" > ~/.ssh/id_deploy
          chmod 600 ~/.ssh/id_deploy
          ssh-keyscan -H "${{ secrets.DEPLOY_SSH_HOST }}" >> ~/.ssh/known_hosts

      - name: Refuse if .env.production has CHANGE_ME (remote)
        run: |
          ssh -i ~/.ssh/id_deploy -o StrictHostKeyChecking=yes \
            "${{ secrets.DEPLOY_SSH_USER }}@${{ secrets.DEPLOY_SSH_HOST }}" \
            "cd '${{ secrets.DEPLOY_PATH }}' && bash scripts/validate-env.sh production"

      - name: Rsync sources
        run: |
          rsync -az --delete \
            --exclude '.git' --exclude 'node_modules' --exclude '__pycache__' \
            --exclude '.venv' --exclude 'data/' --exclude 'logs/' \
            -e "ssh -i ~/.ssh/id_deploy -o StrictHostKeyChecking=yes" \
            ./ \
            "${{ secrets.DEPLOY_SSH_USER }}@${{ secrets.DEPLOY_SSH_HOST }}:${{ secrets.DEPLOY_PATH }}/"

      - name: Remote compose up
        run: |
          ssh -i ~/.ssh/id_deploy -o StrictHostKeyChecking=yes \
            "${{ secrets.DEPLOY_SSH_USER }}@${{ secrets.DEPLOY_SSH_HOST }}" \
            "cd '${{ secrets.DEPLOY_PATH }}' && \
             docker compose -f assets/docker/docker-compose.prod.yml --env-file .env.production up -d --build"

      - name: Smoke test (production health)
        run: |
          ssh -i ~/.ssh/id_deploy -o StrictHostKeyChecking=yes \
            "${{ secrets.DEPLOY_SSH_USER }}@${{ secrets.DEPLOY_SSH_HOST }}" \
            "curl -fsS -m 10 https://{{proxy_domain}}{{health_endpoint}}/live"
