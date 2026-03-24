---
name: frappe-frontend
description: Generic Frappe React frontend patterns — Doppio routing, shadcn components, metadata-driven UI, hooks, API integration, and safe utilities. Use for ANY Frappe custom app.
---

# Frappe Frontend Patterns

Generic React patterns for Frappe apps. Works with Doppio, Vite, TypeScript, and shadcn/ui.

## When to Use This Skill

- Building React SPAs for Frappe apps
- Creating metadata-driven list/detail pages
- Implementing RBAC-aware UI
- Setting up routing under `/frontend/*`
- Integrating with Frappe APIs from React

## Architecture Rules

1. **All React routes under `/frontend/*`**
2. **API paths under `/api/*`** — never prefix with `/frontend`
3. **Public pages under `/s/<token>`** — server-rendered, not React
4. **No `/dashboard` route** — use `/frontend`
5. **Keep code minimal and product-focused**

## Project Structure

```
frontend/
├── src/
│   ├── api/
│   │   └── frappe.ts              # API client
│   ├── components/
│   │   ├── form/
│   │   │   └── GenericDocPage.tsx
│   │   ├── list/
│   │   │   ├── GenericListPage.tsx
│   │   │   ├── GenericList.tsx
│   │   │   ├── ListToolbar.tsx
│   │   │   └── ListFilters.tsx
│   │   └── ui/
│   │       ├── AppLayout.tsx
│   │       ├── StatusBadge.tsx
│   │       ├── ErrorBanner.tsx
│   │       ├── LoadingSpinner.tsx
│   │       └── index.ts
│   ├── config/
│   │   ├── navigation.ts
│   │   └── masters.ts
│   ├── features/
│   │   └── safeList/
│   │       ├── useSafeList.ts
│   │       ├── useSafeDetail.ts
│   │       └── useSafeCreate.ts
│   ├── hooks/
│   ├── lib/
│   │   └── realtime.ts
│   ├── pages/
│   │   ├── Dashboard.tsx
│   │   └── [feature].tsx
│   ├── types/
│   │   └── roles.ts
│   ├── utils/
│   │   └── number.ts
│   ├── App.tsx
│   └── main.tsx
├── tests/
│   └── [app].spec.ts
├── package.json
├── vite.config.ts
└── playwright.config.ts
```

## FrappeProvider Setup

```tsx
// App.tsx
import { FrappeProvider } from 'frappe-react-sdk'
import { REALTIME_CONFIG } from './lib/realtime'

function App() {
  return (
    <FrappeProvider
      socketPort={REALTIME_CONFIG.enabled ? REALTIME_CONFIG.socketPort : undefined}
      url={REALTIME_CONFIG.frappeUrl}
    >
      <RouterProvider router={router} />
    </FrappeProvider>
  )
}
```

## Realtime Configuration

```typescript
// lib/realtime.ts
export const REALTIME_CONFIG = {
  enabled: import.meta.env.VITE_USE_REALTIME === 'true',
  socketPort: import.meta.env.VITE_SOCKET_PORT || '9000',
  frappeUrl: import.meta.env.VITE_FRAPPE_URL || '/',
}
```

```env
# .env.local
VITE_USE_REALTIME=false
VITE_SOCKET_PORT=9000
VITE_FRAPPE_URL=/
```

## API Client Pattern

```typescript
// api/frappe.ts
import { createFrappeFetcher } from 'frappe-react-sdk'

export const frappeCall = createFrappeFetcher()

export async function getSafeListRows(
  doctype: string,
  filters?: Record<string, unknown>,
  pageLength = 20,
  start = 0
) {
  return frappeCall.post(
    '[APP_NAME].api.safe_list_api.get_safe_list_rows',
    { doctype, filters, page_length: pageLength, start }
  )
}

export async function getSafeListSchema(doctype: string) {
  return frappeCall.post(
    '[APP_NAME].api.safe_list_api.get_safe_list_schema',
    { doctype }
  )
}

export interface SafeListRow {
  name: string
  values: Record<string, unknown>
  display_values: Record<string, string>
}

export interface SafeListSchema {
  doctype: string
  columns: SchemaColumn[]
  permissions: UserPermissions
}
```

## Generic List Page

```tsx
// components/list/GenericListPage.tsx
import { useState, useMemo } from 'react'
import { useParams, useSearchParams } from 'react-router-dom'
import { AppLayout, PageHeader, ErrorBanner, LoadingSpinner } from '../ui'
import { GenericList } from './GenericList'
import { useSafeList } from '../../features/safeList/useSafeList'

export function GenericListPage() {
  const { doctype } = useParams<{ doctype: string }>()
  const [searchParams] = useSearchParams()
  const [searchInput, setSearchInput] = useState('')
  const debouncedSearch = useDebounce(searchInput, 300)
  
  const filters = useMemo(() => {
    const f: Record<string, string> = {}
    searchParams.forEach((value, key) => { f[key] = value })
    return f
  }, [searchParams])
  
  const { rows, schema, loading, error, refresh } = useSafeList(
    doctype!, filters, debouncedSearch
  )
  
  if (loading) return <LoadingSpinner />
  if (error) return <ErrorBanner error={error} onRetry={refresh} />
  
  return (
    <AppLayout>
      <PageHeader title={doctype} />
      <GenericList rows={rows} schema={schema} />
    </AppLayout>
  )
}
```

## Generic Detail Page

```tsx
// components/form/GenericDocPage.tsx
import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { AppLayout, PageHeader, ErrorBanner, SuccessBanner } from '../ui'
import { useSafeDetail } from '../../features/safeList/useSafeDetail'

export function GenericDocPage() {
  const { doctype, name } = useParams<{ doctype: string; name: string }>()
  const navigate = useNavigate()
  const [isEditing, setIsEditing] = useState(false)
  const [formData, setFormData] = useState<Record<string, unknown>>({})
  
  const { doc, schema, loading, error, updateDoc } = useSafeDetail(doctype!, name!)
  
  const handleSave = async () => {
    const result = await updateDoc(name!, formData)
    if (result.success) setIsEditing(false)
  }
  
  return (
    <AppLayout>
      <PageHeader
        title={name!}
        onBack={() => navigate(`/frontend/list/${doctype}`)}
        actions={
          isEditing ? (
            <>
              <button onClick={() => setIsEditing(false)}>Cancel</button>
              <button onClick={handleSave}>Save</button>
            </>
          ) : <button onClick={() => setIsEditing(true)}>Edit</button>
        }
      />
      {error && <ErrorBanner error={error} />}
      {/* Render form fields dynamically */}
    </AppLayout>
  )
}
```

## Hooks Pattern

```typescript
// features/safeList/useSafeList.ts
import { useState, useEffect } from 'react'
import { getSafeListRows, getSafeListSchema } from '../../api/frappe'

export function useSafeList(
  doctype: string,
  filters?: Record<string, unknown>,
  search?: string
) {
  const [rows, setRows] = useState([])
  const [schema, setSchema] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  
  const fetchData = async () => {
    setLoading(true)
    try {
      const [schemaRes, rowsRes] = await Promise.all([
        getSafeListSchema(doctype),
        getSafeListRows(doctype, filters)
      ])
      setSchema(schemaRes.message)
      setRows(rowsRes.message.rows)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }
  
  useEffect(() => { fetchData() }, [doctype, JSON.stringify(filters), search])
  
  return { rows, schema, loading, error, refresh: fetchData }
}
```

## Role-Based Navigation

```typescript
// types/roles.ts
export type UserRole = 'admin' | 'owner' | 'operations' | 'guest'

export function getUserRole(userType: string | null | undefined): UserRole {
  if (!userType) return 'guest'
  const t = userType.toLowerCase()
  if (t.includes('admin') || t.includes('system manager')) return 'admin'
  if (t.includes('operations') || t.includes('support')) return 'operations'
  if (t.includes('owner')) return 'owner'
  return 'owner'
}
```

## Safe Numeric Utilities

```typescript
// utils/number.ts
export function isValidNumber(value: unknown): value is number {
  return typeof value === 'number' && isFinite(value)
}

export function safeToFixed(value: unknown, digits = 2, fallback = '-'): string {
  return isValidNumber(value) ? value.toFixed(digits) : fallback
}

export function safeRound(value: unknown, fallback = 0): number {
  return isValidNumber(value) ? Math.round(value) : fallback
}
```

## AppLayout Component

```tsx
// components/ui/AppLayout.tsx
import { ReactNode } from 'react'
import { Link, useLocation } from 'react-router-dom'

interface AppLayoutProps {
  children: ReactNode
  navItems?: { path: string; label: string }[]
}

export function AppLayout({ children, navItems }: AppLayoutProps) {
  const location = useLocation()
  
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 flex justify-between h-16">
          <div className="flex space-x-8">
            {navItems?.map(item => (
              <Link
                key={item.path}
                to={item.path}
                className={`px-1 pt-1 border-b-2 text-sm font-medium ${
                  location.pathname === item.path
                    ? 'border-blue-500 text-gray-900'
                    : 'border-transparent text-gray-500'
                }`}
              >
                {item.label}
              </Link>
            ))}
          </div>
        </div>
      </nav>
      <main className="max-w-7xl mx-auto py-6 px-4">{children}</main>
    </div>
  )
}
```

## Playwright Test Pattern

```typescript
// tests/[app].spec.ts
import { test, expect } from '@playwright/test'

test('Page loads without crash', async ({ page }) => {
  const errors: string[] = []
  page.on('pageerror', e => errors.push(e.message))
  
  await page.goto('/frontend')
  await page.waitForTimeout(2000)
  
  await expect(page.locator('body')).toBeVisible()
  expect(errors).not.toContainEqual(expect.stringContaining('is not defined'))
})

test('No /frontend/api calls', async ({ page }) => {
  const bad: string[] = []
  page.on('request', req => {
    if (req.url().includes('/frontend/api')) bad.push(req.url())
  })
  
  await page.goto('/frontend/list/[DocType]')
  await page.waitForTimeout(3000)
  
  expect(bad).toHaveLength(0)
})
```

## Common Pitfalls

1. **Never use `/frontend/api/*`** — use `/api/*`
2. **Never create routes outside `/frontend/*`**
3. **Always handle null/undefined** — use `safeToFixed`, optional chaining
4. **Don't use `.toFixed()` directly** — crashes on undefined
5. **Filter contract** — send dict, not JSON string
6. **Realtime is optional** — always have polling fallback
