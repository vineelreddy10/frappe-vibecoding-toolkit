# Best Practices

Production-grade practices for ANY Frappe custom app.

## Architecture

### 3-Layer Model
1. **Admin** (`/app/*`) — Frappe Desk for administrators
2. **Owner** (`/frontend/*`) — React SPA for authenticated users
3. **Public** (`/s/<token>`) — Server-rendered for guests

### Route Rules
- ALL React routes under `/frontend/*`
- ALL API routes under `/api/*`
- NEVER prefix API with `/frontend`
- Public pages are Jinja, not React

## Backend

### Safe List API
```python
# GOOD: Generic, RBAC-safe
@frappe.whitelist()
def get_safe_list_rows(doctype: str, filters: str | dict | None = None):
    # Parse filters, enforce RBAC, return normalized
    pass

# BAD: Hardcoded, no RBAC
@frappe.whitelist()
def get_items():
    return frappe.get_all("Item")
```

### Service Layer
```python
# GOOD: Business logic in services
class [Feature]Service:
    @staticmethod
    def get_records(owner: str) -> list[dict]:
        # Logic here
        pass

# BAD: Logic in API
@frappe.whitelist()
def get_items():
    # Mixed concerns
    pass
```

### RBAC
```python
# GOOD: Centralized
def get_owner_profile(user=None):
    if is_admin(user):
        return "Administrator"
    return frappe.db.get_value("Owner Profile", {"user": user}, "name")

# BAD: Scattered checks
if frappe.session.user != "Administrator":
    # inconsistent
```

### Deduplication
```python
# GOOD: Time-window
def is_duplicate(event, record, window=60):
    window_start = add_to_date(now_datetime(), seconds=-window)
    return bool(frappe.db.exists("Event Log", {
        "event": event, "record": record,
        "creation": [">", window_start]
    }))

# BAD: No deduplication
def create_event(event, record):
    # Duplicates on retry
    frappe.get_doc({...}).insert()
```

## Frontend

### Routes
```typescript
// GOOD
<Route path="/frontend/items" element={<Items />} />

// BAD
<Route path="/items" element={<Items />} />
```

### API Calls
```typescript
// GOOD
frappeCall.post('/api/method/app.api.get_items')

// BAD
frappeCall.post('/frontend/api/method/app.api.get_items')
```

### Numbers
```typescript
// GOOD
import { safeToFixed } from '../utils/number'
safeToFixed(value, 2)

// BAD
value.toFixed(2)  // Crashes on undefined
```

### Filters
```typescript
// GOOD: Dict
const filters = { field: "value" }
await frappeCall.post('get_safe_list_rows', { filters })

// BAD: String
const filters = JSON.stringify({ field: "value" })
```

## Testing

### Unit Tests
```python
# GOOD: Isolated
class TestFeature(unittest.TestCase):
    def setUp(self):
        frappe.db.begin()
    def tearDown(self):
        frappe.db.rollback()

# BAD: No isolation
def test_create():
    # Leaves test data
```

### RBAC Tests
```python
# GOOD: All roles
def test_admin(): frappe.set_user("Administrator")
def test_owner(): frappe.set_user("owner@example.com")
def test_guest(): frappe.set_user("Guest")

# BAD: Only admin
def test_admin():
    frappe.set_user("Administrator")
```

### E2E Tests
```typescript
// GOOD: Error checking
test('No crashes', async ({ page }) => {
  const errors = []
  page.on('pageerror', e => errors.push(e.message))
  await page.goto('/frontend/items')
  expect(errors).toHaveLength(0)
})

// GOOD: API path validation
test('No wrong paths', async ({ page }) => {
  const bad = []
  page.on('request', req => {
    if (req.url().includes('/frontend/api')) bad.push(req.url())
  })
  expect(bad).toHaveLength(0)
})
```

## Deployment

### Pre-deploy
```bash
# ALWAYS check disk
df -h /

# ALWAYS clean
docker builder prune -a -f
```

### Asset Sync
```bash
# ALWAYS sync after build
docker cp backend:/path/css/. /tmp/css/
docker cp /tmp/css/. frontend:/path/css/
```

### Never Do
- ❌ Prune volumes (deletes database)
- ❌ Deploy with <10GB free
- ❌ Skip smoke tests
- ❌ Deploy without migrations

## Code Quality

### Types
```python
# GOOD
def get_items(owner: str | None = None) -> list[dict]:
    pass

# BAD
def get_items(owner=None):
    pass
```

### Error Handling
```python
# GOOD
try:
    result = do_something()
except frappe.ValidationError as e:
    return {"success": False, "error": str(e)}

# BAD
try:
    result = do_something()
except:
    pass
```

### Documentation
```python
# GOOD
def get_items(owner: str | None = None) -> list[dict]:
    """Get items for owner.

    Args:
        owner: Owner profile, None for admin
    Returns:
        List of item dicts
    """
    pass

# BAD
def get_items(owner=None):
    pass
```

## SYSTEM_STATE

### Update After Each Phase
```markdown
## Phase X: Feature — DATE
**Status**: ✅ COMPLETED
**Files**: [list]
**Tests**: [list]
```

### Track Issues
```markdown
## Known Issues
### Issue: Description
- Severity: Low/Medium/High
- Status: Open/Fixed
```

### Document Decisions
```markdown
## Decision: [What]
- Context: [Why]
- Decision: [What]
- Consequences: [Impact]
```
