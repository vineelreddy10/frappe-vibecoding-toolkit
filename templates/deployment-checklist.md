# Deployment Checklist

Use before every production deployment.

## Pre-Deploy

- [ ] All changes committed to main branch
- [ ] Disk space >15GB free: `df -h /`
- [ ] Docker healthy: `docker ps`
- [ ] Build cache cleaned: `docker builder prune -a -f`
- [ ] apps.json updated with correct repo URL
- [ ] .env file has correct passwords

## Build

- [ ] Docker image builds successfully
- [ ] No errors in build output
- [ ] Image tagged correctly: `[APP_NAME]:v16`

## Deploy

- [ ] Services restarted: `docker compose up -d`
- [ ] Migrations run: `bench --site [SITE] migrate`
- [ ] Assets built: `bench --site [SITE] build`
- [ ] Assets synced to frontend container
- [ ] Caches cleared

## Smoke Tests

- [ ] API ping: `curl http://localhost:8080/api/method/ping`
- [ ] Frontend loads: `curl http://localhost:8080/frontend`
- [ ] No 404 errors in frontend logs
- [ ] No 500 errors in frontend logs
- [ ] Login works
- [ ] Key API endpoints respond

## Post-Deploy

- [ ] Build cache cleaned
- [ ] Disk space checked
- [ ] SYSTEM_STATE.md updated
- [ ] Git tag created for release

## Rollback Plan

If deployment fails:
1. `docker compose down`
2. Restore apps.json from backup
3. Rebuild with previous commit
4. `docker compose up -d`
5. Run migrations if needed
