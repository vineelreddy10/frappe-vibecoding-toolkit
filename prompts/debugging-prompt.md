# Debugging Prompt

Use this prompt to debug issues in a Frappe app.

```
Debug an error in [APP_NAME].

## Error
```
[ERROR_MESSAGE]
```

## Context
- Page/API: [WHERE]
- When: [WHEN]
- User role: [ROLE]

## Steps
1. Reproduce — exact steps
2. Check SYSTEM_STATE — past issues
3. Isolate — backend or frontend?
4. Check common issues:
   - .toFixed() on undefined
   - Wrong API path (/frontend/api/*)
   - Filter type mismatch
   - Missing variable declaration
   - Permission denied
   - Docker asset sync
5. Root cause — actual cause
6. Fix — minimal change
7. Verify — test exact scenario
8. Document — add to SYSTEM_STATE
```
