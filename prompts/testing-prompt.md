# Testing Prompt

Use this prompt to create comprehensive tests.

```
Create tests for [FEATURE] in [APP_NAME].

## Backend Tests
File: [APP_NAME]/[MODULE]/tests/test_[feature].py

### Test Cases
1. Happy path — normal operation succeeds
2. Validation — invalid input throws error
3. RBAC — admin, owner, guest see correct data
4. Edge cases — null, missing, duplicates

### RBAC Matrix
| Role | Can Create | Can Read | Can Update | Can Delete |
|------|-----------|----------|------------|------------|
| Admin | ✅ | ✅ | ✅ | ✅ |
| Owner | ✅ | Own | Own | Own |
| Guest | ❌ | ❌ | ❌ | ❌ |

## E2E Tests
File: frontend/tests/[app].spec.ts

### Test Cases
1. Page loads without crash
2. No console errors
3. No /frontend/api calls
4. Filter contract (dict not string)
5. Navigation works
6. Error states display

## Run Commands
- Backend: `bench --site test.localhost run-tests --app [APP_NAME]`
- E2E: `cd frontend && npx playwright test`
```
