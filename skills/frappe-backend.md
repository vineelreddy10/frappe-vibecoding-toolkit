---
name: frappe-backend
description: Generic Frappe backend patterns — DocType creation, Safe List API, service layers, RBAC, hooks, deduplication, and controller lifecycle. Use for ANY Frappe custom app.
---

# Frappe Backend Patterns

Generic, reusable patterns for building Frappe custom apps. Works for ERP, SaaS, HES, internal tools — any Frappe application.

## When to Use This Skill

- Creating DocTypes
- Writing whitelisted API endpoints
- Implementing RBAC and permissions
- Building service layers
- Setting up hooks and scheduler events
- Adding deduplication and reliability

## App Structure

```
[APP_NAME]/
├── [APP_NAME]/
│   ├── __init__.py
│   ├── hooks.py
│   ├── modules.txt
│   ├── patches.txt
│   ├── api/
│   │   ├── __init__.py
│   │   ├── safe_list_api.py      # Generic CRUD
│   │   └── [feature]_api.py      # Feature-specific
│   ├── doctype/
│   │   └── [doctype_snake]/
│   │       ├── [doctype_snake].json
│   │       ├── [doctype_snake].py
│   │       └── test_[doctype_snake].py
│   ├── services/
│   │   ├── __init__.py
│   │   └── [feature]_service.py
│   ├── utils/
│   │   ├── __init__.py
│   │   └── permissions.py
│   └── tests/
│       └── test_[feature].py
├── frontend/
├── deploy/
├── .github/
└── pyproject.toml
```

## hooks.py Pattern

```python
app_name = "[APP_NAME]"
app_title = "[App Title]"
app_publisher = "[Your Name]"
app_description = "[Description]"
app_version = "0.0.1"

scheduler_events = {
    "hourly": [
        "[APP_NAME].services.cleanup_service.expire_stale_records",
    ],
    "daily": [
        "[APP_NAME].services.cleanup_service.recompute_metadata",
    ],
}

website_route_rules = [
    {"from_route": "/s/<path:token>", "to_route": "public_portal/scan"},
]
```

## Safe List API Pattern

Generic CRUD with RBAC — works for ANY doctype:

```python
import frappe
from frappe import _
import json

@frappe.whitelist()
def get_safe_list_rows(
    doctype: str,
    filters: str | dict | None = None,
    order_by: str = "modified desc",
    page_length: int = 20,
    start: int = 0,
    search: str | None = None
) -> dict:
    """Fetch list rows with RBAC enforcement."""
    if not frappe.db.exists("DocType", doctype):
        frappe.throw(_("DocType {0} does not exist").format(doctype))
    
    filter_list = _parse_filters(filters)
    if search:
        filter_list.append(["name", "like", f"%{search}%"])
    
    rows = frappe.get_list(
        doctype,
        filters=filter_list,
        fields=["name", "*"],
        order_by=order_by,
        limit_page_length=page_length,
        limit_start=start,
    )
    
    return {
        "rows": [
            {"name": r.name, "values": r, "display_values": _get_display(doctype, r)}
            for r in rows
        ],
        "total_count": frappe.db.count(doctype, filters=filter_list),
        "page": (start // page_length) + 1,
        "page_length": page_length,
    }


@frappe.whitelist()
def get_safe_list_schema(doctype: str) -> dict:
    """Get doctype schema with user permissions."""
    meta = frappe.get_meta(doctype)
    return {
        "doctype": doctype,
        "columns": [
            {
                "fieldname": f.fieldname,
                "fieldtype": f.fieldtype,
                "label": f.label,
                "options": f.options,
                "in_list_view": f.in_list_view,
            }
            for f in meta.fields
            if f.fieldtype in ["Data", "Int", "Float", "Currency", "Date",
                               "Datetime", "Select", "Link", "Check", "Percent"]
        ],
        "permissions": {
            "can_read": frappe.has_permission(doctype, "read"),
            "can_write": frappe.has_permission(doctype, "write"),
            "can_create": frappe.has_permission(doctype, "create"),
            "can_delete": frappe.has_permission(doctype, "delete"),
        },
    }


@frappe.whitelist(methods=["POST"])
def create_safe_doc(doctype: str, doc: dict) -> dict:
    """Create document with validation."""
    try:
        if not frappe.has_permission(doctype, "create"):
            frappe.throw(_("Not permitted"))
        new_doc = frappe.get_doc({"doctype": doctype, **doc})
        new_doc.insert()
        return {"success": True, "data": {"name": new_doc.name}}
    except Exception as e:
        frappe.log_error(f"create_safe_doc: {e}")
        return {"success": False, "error": str(e)}


@frappe.whitelist(methods=["POST"])
def update_safe_doc(doctype: str, name: str, doc: dict) -> dict:
    """Update document with validation."""
    try:
        if not frappe.has_permission(doctype, "write"):
            frappe.throw(_("Not permitted"))
        existing = frappe.get_doc(doctype, name)
        existing.update(doc)
        existing.save()
        return {"success": True, "data": {"name": existing.name}}
    except Exception as e:
        frappe.log_error(f"update_safe_doc: {e}")
        return {"success": False, "error": str(e)}


@frappe.whitelist(methods=["POST"])
def delete_safe_doc(doctype: str, name: str) -> dict:
    """Delete document with permission check."""
    try:
        if not frappe.has_permission(doctype, "delete"):
            frappe.throw(_("Not permitted"))
        frappe.delete_doc(doctype, name)
        return {"success": True}
    except Exception as e:
        frappe.log_error(f"delete_safe_doc: {e}")
        return {"success": False, "error": str(e)}


def _parse_filters(filters: str | dict | None) -> list:
    if not filters:
        return []
    if isinstance(filters, str):
        filters = json.loads(filters)
    if isinstance(filters, dict):
        return [[k, "=", v] for k, v in filters.items()]
    return filters


def _get_display(doctype: str, row: dict) -> dict:
    meta = frappe.get_meta(doctype)
    return {
        f.fieldname: frappe.format(row.get(f.fieldname), f.as_dict())
        for f in meta.fields if f.fieldname in row
    }
```

## RBAC Permission Pattern

```python
# utils/permissions.py
import frappe

def is_admin(user: str | None = None) -> bool:
    user = user or frappe.session.user
    return user == "Administrator" or "System Manager" in frappe.get_roles(user)

def get_owner_profile(user: str | None = None) -> str | None:
    user = user or frappe.session.user
    if is_admin(user):
        return "Administrator"
    return frappe.db.get_value("Owner Profile", {"user": user}, "name")

def user_can_access(owner_field: str, user: str | None = None) -> bool:
    if is_admin(user):
        return True
    profile = get_owner_profile(user)
    return profile == owner_field
```

## Service Layer Pattern

```python
# services/[feature]_service.py
import frappe
from frappe import _

class [Feature]Service:
    @staticmethod
    def get_records(owner_profile: str) -> list[dict]:
        if owner_profile == "Administrator":
            return frappe.get_all("[DocType]", fields=["*"])
        return frappe.get_all(
            "[DocType]",
            filters={"owner_profile": owner_profile},
            fields=["*"],
            ignore_permissions=True,
        )
    
    @staticmethod
    def create_record(data: dict) -> dict:
        _validate_required(data, ["[field1]", "[field2]"])
        doc = frappe.get_doc({"doctype": "[DocType]", **data})
        doc.insert(ignore_permissions=True)
        return {"success": True, "name": doc.name}
    
    @staticmethod
    def update_status(name: str, status: str) -> dict:
        valid = ["[Status1]", "[Status2]", "[Status3]"]
        if status not in valid:
            frappe.throw(_("Invalid status: {0}").format(status))
        frappe.db.set_value("[DocType]", name, "status", status)
        frappe.db.commit()
        return {"success": True}

def _validate_required(data: dict, fields: list[str]):
    missing = [f for f in fields if not data.get(f)]
    if missing:
        frappe.throw(_("Missing: {0}").format(", ".join(missing)))
```

## Deduplication Pattern

```python
def is_duplicate(event_type: str, record: str, window_seconds: int = 60) -> bool:
    from frappe.utils import add_to_date, now_datetime
    window_start = add_to_date(now_datetime(), seconds=-window_seconds)
    return bool(frappe.db.exists("[Event Log DocType]", {
        "event_type": event_type,
        "record": record,
        "creation": [">", window_start],
    }))
```

## Controller Lifecycle

```python
# doctype/[doctype_snake]/[doctype_snake].py
import frappe
from frappe.model.document import Document

class [DocTypePascal](Document):
    def validate(self):
        self.validate_dates()
        self.calculate_totals()
    
    def before_insert(self):
        self.set_defaults()
    
    def on_update(self):
        self.update_related()
    
    def on_trash(self):
        self.cleanup_dependencies()
    
    def validate_dates(self):
        if self.end_date and self.start_date > self.end_date:
            frappe.throw("End date must be after start date")
    
    def calculate_totals(self):
        self.total = sum(d.amount for d in self.items or [])
    
    def set_defaults(self):
        if not self.status:
            self.status = "Draft"
```

## Background Jobs

```python
frappe.enqueue(
    "[APP_NAME].services.[feature]_service.heavy_task",
    queue="long",
    timeout=600,
    data=data_dict,
)
```

## Email Notifications

```python
frappe.sendmail(
    recipients=[email],
    subject="[Subject]",
    message="<p>[Body]</p>",
    reference_doctype="[DocType]",
    reference_name=doc.name,
)
```

## Testing Pattern

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
    
    def test_create(self):
        result = [Feature]Service.create_record({"[field]": "value"})
        self.assertTrue(result["success"])
    
    def test_invalid_status(self):
        with self.assertRaises(frappe.ValidationError):
            [Feature]Service.update_status("TEST-001", "Invalid")
```
