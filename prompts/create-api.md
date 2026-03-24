# API Creation Prompt

Use this prompt to create Frappe API endpoints.

```
Create API endpoints for [APP_NAME].[MODULE] module.

## Endpoints
| Method | Function | Auth | Description |
|--------|----------|------|-------------|
| POST | [method_name] | [Guest/Owner/Admin] | [description] |
| POST | [method_name] | [Guest/Owner/Admin] | [description] |

## Pattern
Use Safe List API pattern:
- get_safe_list_rows(doctype, filters, ...)
- get_safe_list_schema(doctype)
- create_safe_doc(doctype, doc)
- update_safe_doc(doctype, name, doc)
- delete_safe_doc(doctype, name)

## RBAC
- Admin: [permissions]
- Owner: [permissions]
- Guest: [permissions]

## Validation
- Required fields: [list]
- Type checking: [rules]
- Business rules: [rules]

## Response Format
```json
{
  "success": true,
  "data": {},
  "error": null
}
```

## File
Create: [APP_NAME]/[MODULE]/api/[feature]_api.py
```
