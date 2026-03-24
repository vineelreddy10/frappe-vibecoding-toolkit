# Frappe Custom App Project Structure

Standard structure for ANY Frappe custom app.

```
[APP_NAME]/
├── [APP_NAME]/
│   ├── __init__.py
│   ├── hooks.py
│   ├── modules.txt
│   ├── patches.txt
│   ├── api/
│   │   ├── __init__.py
│   │   ├── safe_list_api.py         # Generic CRUD
│   │   └── [feature]_api.py
│   ├── doctype/
│   │   └── [doctype_snake]/
│   │       ├── __init__.py
│   │       ├── [doctype_snake].json
│   │       ├── [doctype_snake].py
│   │       └── test_[doctype_snake].py
│   ├── services/
│   │   ├── __init__.py
│   │   └── [feature]_service.py
│   ├── utils/
│   │   ├── __init__.py
│   │   └── permissions.py
│   ├── templates/
│   │   └── pages/
│   └── tests/
│       ├── __init__.py
│       └── test_[feature].py
├── frontend/
│   ├── src/
│   │   ├── api/frappe.ts
│   │   ├── components/
│   │   │   ├── form/
│   │   │   ├── list/
│   │   │   └── ui/
│   │   ├── config/
│   │   ├── features/safeList/
│   │   ├── hooks/
│   │   ├── lib/realtime.ts
│   │   ├── pages/
│   │   ├── types/roles.ts
│   │   ├── utils/number.ts
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── tests/
│   ├── package.json
│   ├── vite.config.ts
│   ├── playwright.config.ts
│   └── tsconfig.json
├── deploy/
│   ├── deploy.sh
│   └── rollback.sh
├── .github/workflows/
│   ├── deploy.yml
│   └── test.yml
├── pyproject.toml
├── README.md
├── SYSTEM_STATE.md
└── .gitignore
```

## Conventions

### Backend
- Safe List API for generic CRUD
- Services for business logic
- utils/permissions.py for RBAC
- tests/ in each module

### Frontend
- Routes under /frontend/*
- API calls to /api/*
- Shared components in components/ui/
- One file per route in pages/

### Deployment
- frappe_docker based
- GitHub Actions CI/CD

### Testing
- Backend: bench run-tests
- Frontend: Playwright E2E
- RBAC: separate test cases per role
