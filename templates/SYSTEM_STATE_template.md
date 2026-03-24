# [APP_NAME] System State

**Last Updated**: [DATE]

---

## Executive Summary

**Status**: [✅ STABLE | ⚠️ WARNING | 🚨 CRITICAL]

[Brief summary]

---

## Architecture

| Layer | Route | Technology |
|-------|-------|------------|
| Admin | /app/* | Frappe Desk |
| Owner | /frontend/* | React SPA |
| Public | /s/<token> | Server-rendered |

---

## API Inventory

### Public APIs (allow_guest=True)
- [APP_NAME].[module].api.[method]

### Owner APIs (Authenticated)
- [APP_NAME].[module].api.[method]

### Admin APIs (Admin Only)
- [APP_NAME].[module].api.[method]

---

## DocTypes

| DocType | Module | Purpose |
|---------|--------|---------|
| [DocType] | [module] | [purpose] |

---

## Routes

- /frontend — Dashboard
- /frontend/[route] — [Page]

---

## Known Issues

### [Issue Description]
- **Severity**: [Low/Medium/High]
- **Status**: [Open/Fixed]
- **Fix**: [If fixed]

---

## Decision Log

### [DATE]: [Decision]
- **Context**: [Why]
- **Decision**: [What]
- **Consequences**: [Impact]

---

## Next Steps

1. [ ] [Task]
2. [ ] [Task]
