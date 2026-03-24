# Build Feature Prompt

Use this prompt to build a new Frappe feature from scratch.

```
I need to build [FEATURE_NAME] for my Frappe app [APP_NAME].

## Module
[MODULE_NAME] — e.g., items, recovery, notifications

## DocTypes to Create
- [DocType1] with fields: [field1], [field2], [field3]
- [DocType2] with fields: [field1], [field2]

## APIs Needed
- [api_method_1] — [description]
- [api_method_2] — [description]

## Frontend Routes
- /frontend/[route1] — [description]
- /frontend/[route2] — [description]

## RBAC Rules
- Admin: [what admin can do]
- Owner: [what owner can do]
- Guest: [what guest can do]

## Phase Plan
Please create:
1. Phase 1: DocType + Service Layer (backend)
2. Phase 2: API Endpoints (backend)
3. Phase 3: Frontend Pages (React)
4. Phase 4: Tests (unit + E2E)

## Constraints
- Routes under /frontend/*
- APIs under /api/*
- Use Safe List API pattern
- Use safe numeric utilities
- Filter contract: dict, not string
```
