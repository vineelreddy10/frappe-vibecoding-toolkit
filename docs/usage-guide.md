# Usage Guide

How to use the Frappe Vibecoding Toolkit for ANY Frappe app.

## Starting a New Feature

### Option 1: Full Feature Build

```
Use build-feature prompt to build [FEATURE_NAME]:

Module: [MODULE]
DocTypes: [DOCTYPE1], [DOCTYPE2]
APIs: [method1], [method2]
Routes: /frontend/[route1], /frontend/[route2]
RBAC: Admin sees all, Owner sees own, Guest denied
```

### Option 2: Individual Components

```
# Create DocType
Use frappe-backend skill to create [DOCTYPE] with fields [field1], [field2]

# Create API
Use create-api prompt to add [method] endpoint

# Create Frontend
Use create-frontend-page prompt to build /frontend/[route]
```

## Development Workflow

### Backend

1. **DocType** → `frappe-backend` skill
2. **Service** → `frappe-backend` skill (service layer pattern)
3. **API** → `create-api` prompt
4. **Tests** → `testing-prompt` prompt
5. **Migrate** → `bench --site [SITE] migrate`

### Frontend

1. **Page** → `frappe-frontend` skill
2. **Hook** → `frappe-frontend` skill (useSafeList/useSafeDetail)
3. **Tests** → `frappe-testing` skill (Playwright)
4. **Build** → `cd frontend && yarn build`

### Full Stack

```
Use build-feature prompt with all requirements listed
```

## Testing

### Unit Tests

```
Use testing-prompt to write tests for [FEATURE]
```

Or:
```bash
bench --site [SITE] run-tests --app [APP_NAME]
```

### E2E Tests

```
Use frappe-testing skill to write Playwright tests for /frontend/[route]
```

Or:
```bash
cd frontend && npx playwright test
```

### RBAC Tests

```
Use testing-prompt to test RBAC for [API]:
- Admin: sees all
- Owner: sees own
- Guest: denied
```

## Deployment

### Local

```bash
bench --site [SITE] migrate
bench start
```

### Production

```
Use deployment-prompt to deploy [APP_NAME] to [VPS_IP]
```

Or:
```bash
ssh root@[VPS_IP]
cd [DEPLOY_DIR]
./deploy/deploy.sh
```

### GitHub Actions

Push to main triggers deploy automatically.

## Debugging

```
Use debugging-prompt:
Error: [ERROR_MESSAGE]
Page/API: [WHERE]
When: [WHEN]
```

## Agent Usage

### Planner

```
@planner Break down the [FEATURE] into phases
```

### Executor

```
@executor Execute phase 1 of the plan
```

### Tester

```
@tester Write and run tests for [FEATURE]
```

### Debugger

```
@debugger Fix the [ERROR] on [PAGE]
```

## Common Patterns

### Safe List API

```
Use frappe-backend skill to create safe_list_api.py with CRUD methods
```

### Metadata-Driven UI

```
Use frappe-frontend skill to create GenericListPage and GenericDocPage
```

### Notification System

```
Use frappe-operations skill to add notification service with deduplication
```

### Docker Deployment

```
Use frappe-deployment skill to create deploy.sh and GitHub Actions
```

## Customization

### Replace Placeholders

All templates use `[PLACEHOLDERS]`:
- `[APP_NAME]` — your app name
- `[MODULE]` — your module name
- `[DOCTYPE]` — your doctype name
- `[VPS_IP]` — your server IP
- `[SITE_NAME]` — your site name
- `[ORG]` — your GitHub org

### Extend Skills

Add your own patterns to `~/.config/opencode/skills/frappe-vibecoding/skills/`

### Add Agents

Define in `oh-my-opencode.json` and create `.md` file in `agents/`
