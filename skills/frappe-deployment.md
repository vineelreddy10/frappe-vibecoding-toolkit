---
name: frappe-deployment
description: Generic Frappe Docker deployment — frappe_docker builds, VPS deploy, CI/CD, asset sync, and low-resource optimization. Use for ANY Frappe custom app.
---

# Frappe Deployment Patterns

Generic Docker deployment for Frappe apps using frappe_docker. Works for any app, any VPS, any scale.

## When to Use This Skill

- Deploying Frappe apps with Docker
- Building custom Docker images
- Setting up CI/CD with GitHub Actions
- Managing VPS deployments
- Optimizing for low-resource servers

## Deployment Architecture

```
GitHub Push → GitHub Actions → SSH to VPS → Docker Build → Restart → Validate
```

### Container Stack

| Container | Purpose |
|-----------|---------|
| backend | Frappe (gunicorn) |
| frontend | Nginx reverse proxy |
| websocket | Socket.IO |
| queue-short | Short job worker |
| queue-long | Long job worker |
| scheduler | Cron jobs |
| db | MariaDB |
| redis-cache | Redis cache |
| redis-queue | Redis queue |

## apps.json Configuration

```json
[
  {
    "url": "https://github.com/frappe/frappe",
    "branch": "version-16"
  },
  {
    "url": "https://github.com/[ORG]/[APP_NAME]",
    "branch": "main"
  }
]
```

## Docker Build Command

```bash
docker build \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=version-16 \
  --build-arg=APPS_JSON_BASE64=$(base64 -w 0 apps.json) \
  --tag=[APP_NAME]:v16 \
  --file=images/custom/Containerfile . \
  --load
```

## Deployment Script Template

```bash
#!/bin/bash
# deploy/deploy.sh
set -e

APP_NAME="[APP_NAME]"
SITE_NAME="[SITE_NAME]"
VPS_DEPLOY_DIR="[DEPLOY_DIR]"  # e.g., /opt/my-app

echo "=== Pre-deploy Checks ==="
df -h /
docker system df

echo "=== Cleaning Up ==="
docker image prune -f
docker builder prune -a -f

echo "=== Building Image ==="
docker build \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=version-16 \
  --build-arg=APPS_JSON_BASE64=$(base64 -w 0 apps.json) \
  --tag=${APP_NAME}:v16 \
  --file=images/custom/Containerfile . \
  --load

echo "=== Restarting Services ==="
docker compose --env-file .env -f compose.prod.yaml up -d

echo "=== Running Migrations ==="
docker exec ${APP_NAME}-backend-1 bench --site ${SITE_NAME} migrate

echo "=== Building Assets ==="
docker exec ${APP_NAME}-backend-1 bench --site ${SITE_NAME} build

echo "=== Syncing Assets to Frontend ==="
docker cp ${APP_NAME}-backend-1:/home/frappe/frappe-bench/sites/assets/frappe/dist/css/. /tmp/css_backend/
docker cp /tmp/css_backend/. ${APP_NAME}-frontend-1:/home/frappe/frappe-bench/sites/assets/frappe/dist/css/
docker cp ${APP_NAME}-backend-1:/home/frappe/frappe-bench/sites/assets/frappe/dist/js/. /tmp/js_backend/
docker cp /tmp/js_backend/. ${APP_NAME}-frontend-1:/home/frappe/frappe-bench/sites/assets/frappe/dist/js/

echo "=== Clearing Caches ==="
docker exec ${APP_NAME}-backend-1 bench --site ${SITE_NAME} clear-cache
docker exec ${APP_NAME}-backend-1 bench --site ${SITE_NAME} clear-website-cache

echo "=== Post-deploy Cleanup ==="
docker builder prune -a -f

echo "=== Smoke Tests ==="
curl -s http://localhost:8080/api/method/ping
docker logs ${APP_NAME}-frontend-1 --tail 20 | grep -E '404|500' || echo "No errors"

echo "=== Done ==="
```

## GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy to VPS

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd [DEPLOY_DIR]
            git pull origin main
            ./deploy/deploy.sh
```

## GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| VPS_HOST | VPS IP address |
| VPS_USER | SSH username |
| VPS_SSH_KEY | SSH private key (PEM) |

## Asset Sync Issue

After `bench build`, CSS/JS files go to the backend's anonymous volume. The frontend container can't access them.

```bash
# Always sync after build
docker cp [APP]-backend-1:/home/frappe/frappe-bench/sites/assets/frappe/dist/css/. /tmp/css/
docker cp /tmp/css/. [APP]-frontend-1:/home/frappe/frappe-bench/sites/assets/frappe/dist/css/

docker cp [APP]-backend-1:/home/frappe/frappe-bench/sites/assets/frappe/dist/js/. /tmp/js/
docker cp /tmp/js/. [APP]-frontend-1:/home/frappe/frappe-bench/sites/assets/frappe/dist/js/
```

## Low-Resource VPS Optimization

### Pre-deploy Cleanup

```bash
docker image prune -f              # Dangling images
docker image prune -a -f           # Unused images
docker builder prune -a -f         # Build cache (~19GB)
docker container prune -f          # Stopped containers
docker network prune -f            # Unused networks
```

### Disk Space Thresholds

| Free Space | Action |
|-----------|--------|
| >15GB | Safe to deploy |
| 10-15GB | Clean up first |
| <10GB | MUST clean up |

### NEVER Delete

- **Volumes** — will delete database
- **Running containers** — will stop services
- **Active images** — will break deployment

## Environment Variables

```env
# .env
MARIADB_ROOT_PASSWORD=[YOUR_DB_PASSWORD]
SITE_NAME=[SITE_NAME]
SITES=[SITE_NAME]
```

## Post-Deploy Validation

```bash
# Check containers
docker ps

# Test API
curl http://localhost:8080/api/method/ping

# Check for errors
docker logs [APP]-frontend-1 --tail 50 | grep -E '404|500'

# Check disk
df -h /
```

## Rollback Procedure

```bash
# SSH to VPS
ssh root@[VPS_IP]
cd [DEPLOY_DIR]

# Restore apps.json
cp apps.json.backup apps.json

# Rebuild with previous commit
git checkout [PREVIOUS_COMMIT]
./deploy/deploy.sh
```

## Log Management

```bash
# View logs
docker logs [APP]-backend-1 -f --tail 100

# Truncate large logs
LOG_PATH=$(docker inspect [APP]-backend-1 | jq -r '.LogPath')
truncate -s 0 "$LOG_PATH"
```

## Common Issues

1. **404 on CSS/JS** — Sync assets from backend to frontend
2. **Disk full** — Clean build cache first
3. **OOM during build** — Reduce parallelism, add swap
4. **Site not accessible** — Check port mapping, firewall
5. **Migrations fail** — Check database connectivity
