# Deployment Prompt

Use this prompt to deploy a Frappe app to production.

```
Deploy [APP_NAME] to production using frappe_docker.

## App Info
- Repo: https://github.com/[ORG]/[APP_NAME]
- Branch: main
- VPS: [VPS_IP]
- Deploy dir: [DEPLOY_DIR]
- Site name: [SITE_NAME]
- Frappe version: version-16

## apps.json
```json
[
  {"url": "https://github.com/frappe/frappe", "branch": "version-16"},
  {"url": "https://github.com/[ORG]/[APP_NAME]", "branch": "main"}
]
```

## Steps
1. Pre-deploy checks (disk >15GB, docker healthy)
2. Clean up (docker builder prune)
3. Build image
4. Restart services
5. Run migrations
6. Build assets
7. Sync assets to frontend
8. Clear caches
9. Smoke tests
10. Post-deploy cleanup

## Smoke Tests
```bash
curl http://localhost:8080/api/method/ping
docker logs [APP]-frontend-1 --tail 50 | grep -E '404|500'
```

## GitHub Secrets
- VPS_HOST, VPS_USER, VPS_SSH_KEY
```
