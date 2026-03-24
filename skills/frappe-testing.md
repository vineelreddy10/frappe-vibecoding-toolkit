---
name: frappe-testing
description: Generic Frappe testing patterns — Playwright E2E, backend unit tests, RBAC validation, API testing, and CI integration. Use for ANY Frappe custom app.
---

# Frappe Testing Patterns

Generic testing patterns for Frappe apps — backend unit tests, Playwright E2E, RBAC validation, and CI integration.

## When to Use This Skill

- Writing Playwright E2E tests
- Writing backend unit tests
- Testing RBAC behavior
- Validating API endpoints
- CI/CD test integration

## Configuration

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test'

export default defineConfig({
  testDir: './tests',
  timeout: 30000,
  retries: 1,
  use: {
    baseURL: 'http://test.localhost',
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
  projects: [{ name: 'chromium', use: { browserName: 'chromium' } }],
})
```

## Page Load Tests

```typescript
import { test, expect } from '@playwright/test'

const PAGES = [
  { path: '/frontend', name: 'Dashboard' },
  { path: '/frontend/list/[DocType]', name: '[DocType] List' },
  { path: '/frontend/[feature]', name: '[Feature]' },
]

for (const page of PAGES) {
  test(`${page.name}: ${page.path} loads without crash`, async ({ page: p }) => {
    const errors: string[] = []
    
    p.on('pageerror', e => errors.push(e.message))
    p.on('console', msg => {
      if (msg.type() === 'error') errors.push(msg.text())
    })
    
    await p.goto(page.path)
    await p.waitForTimeout(2000)
    
    await expect(p.locator('body')).toBeVisible()
    expect(errors).not.toContainEqual(expect.stringContaining('is not defined'))
    expect(errors).not.toContainEqual(expect.stringContaining('Cannot read properties'))
  })
}
```

## Console Error Detection

```typescript
test('No console errors on page load', async ({ page }) => {
  const errors: string[] = []
  
  page.on('pageerror', e => errors.push(e.message))
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push(msg.text())
  })
  
  await page.goto('/frontend')
  await page.waitForTimeout(3000)
  
  const acceptable = ['WebSocket connection', 'ERR_CONNECTION_REFUSED']
  const realErrors = errors.filter(
    e => !acceptable.some(a => e.includes(a))
  )
  
  expect(realErrors).toHaveLength(0)
})
```

## API Path Validation

```typescript
test('No /frontend/api calls (wrong API path)', async ({ page }) => {
  const badRequests: string[] = []
  
  page.on('request', req => {
    if (req.url().includes('/frontend/api')) badRequests.push(req.url())
  })
  
  await page.goto('/frontend/list/[DocType]')
  await page.waitForTimeout(3000)
  
  expect(badRequests).toHaveLength(0)
})
```

## Filter Contract Test

```typescript
test('Filter sends dict format, not JSON string', async ({ page }) => {
  let requestBody: string | null = null
  
  page.on('request', req => {
    if (req.url().includes('get_safe_list_rows')) {
      requestBody = req.postData()
    }
  })
  
  await page.goto('/frontend/list/[DocType]?[field]=[value]')
  await page.waitForTimeout(3000)
  
  expect(requestBody).toBeTruthy()
  const body = JSON.parse(requestBody!)
  expect(typeof body.filters).toBe('object')
})
```

## RBAC Test

```typescript
test('Guest cannot access protected pages', async ({ page }) => {
  await page.context().clearCookies()
  await page.goto('/frontend/[protected]')
  await expect(page).toHaveURL(/login|frontend/)
})
```

## Navigation Flow Test

```typescript
test('Dashboard → List → Detail navigation works', async ({ page }) => {
  await page.goto('/frontend')
  await page.waitForTimeout(2000)
  
  await page.click('a:has-text("[NavItem]")')
  await expect(page).toHaveURL(/frontend\/[path]/)
  
  await page.click('.item-row:first-child')
  await expect(page).toHaveURL(/frontend\/[path]\//)
})
```

## Numeric Safety Test

```typescript
test('No .toFixed() errors on detail pages', async ({ page }) => {
  const errors: string[] = []
  page.on('pageerror', e => errors.push(e.message))
  
  await page.goto('/frontend/[feature]')
  await page.waitForTimeout(2000)
  
  const toFixedErrors = errors.filter(e => e.includes('toFixed'))
  expect(toFixedErrors).toHaveLength(0)
})
```

## Public Page Test

```typescript
test('Public page loads for valid token', async ({ page }) => {
  await page.goto('/s/[VALID_TOKEN]')
  await page.waitForTimeout(2000)
  await expect(page.locator('body')).toBeVisible()
})

test('Public page shows safe error for invalid token', async ({ page }) => {
  await page.goto('/s/INVALID_TOKEN')
  await page.waitForTimeout(2000)
  
  const content = await page.textContent('body')
  expect(content).not.toContain('Traceback')
  expect(content).not.toContain('frappe.exceptions')
})
```

## Backend Unit Test Pattern

```python
import frappe
import unittest

class Test[Feature](unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        frappe.set_user("Administrator")
    
    def setUp(self):
        frappe.db.begin()
    
    def tearDown(self):
        frappe.db.rollback()
    
    def test_happy_path(self):
        from [APP_NAME].services.[feature]_service import [Feature]Service
        result = [Feature]Service.create({"field": "value"})
        self.assertTrue(result["success"])
    
    def test_validation(self):
        with self.assertRaises(frappe.ValidationError):
            [Feature]Service.create({})
    
    def test_admin_access(self):
        frappe.set_user("Administrator")
        result = [Feature]Service.get_all()
        self.assertTrue(len(result) > 0)
    
    def test_owner_access(self):
        frappe.set_user("owner@example.com")
        result = [Feature]Service.get_all()
        # Should only see own records
    
    def test_guest_denied(self):
        frappe.set_user("Guest")
        with self.assertRaises(frappe.PermissionError):
            [Feature]Service.get_all()
```

## Running Tests

```bash
# All Playwright tests
npx playwright test

# Specific file
npx playwright test [app].spec.ts

# With UI
npx playwright test --ui

# Backend tests
bench --site test.localhost run-tests --app [APP_NAME]

# Specific module
bench --site test.localhost run-tests --module [APP_NAME].[module].tests.test_[feature]
```

## CI Integration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: cd frontend && yarn install
      - run: cd frontend && npx playwright install --with-deps chromium
      - run: cd frontend && npx playwright test
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: frontend/playwright-report/
```

## Test Coverage Matrix

| Feature | Unit | RBAC | E2E |
|---------|------|------|-----|
| Create | ✅ | ✅ | ✅ |
| Read | ✅ | ✅ | ✅ |
| Update | ✅ | ✅ | ✅ |
| Delete | ✅ | ✅ | ✅ |
| Validation | ✅ | — | — |
| Error handling | ✅ | — | ✅ |

## Best Practices

1. **Always check console errors** — catch runtime bugs early
2. **Test page loads before interactions**
3. **Validate API paths** — no `/frontend/api` anti-pattern
4. **Test filter contracts** — dict, not string
5. **Test RBAC** — guest, owner, admin see different things
6. **Use timeouts generously** — Frappe API can be slow
