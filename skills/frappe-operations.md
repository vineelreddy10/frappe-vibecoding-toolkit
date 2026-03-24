---
name: frappe-operations
description: Generic Frappe operations patterns — deduplication, reliability, cleanup jobs, health monitoring, notification systems, and admin controls. Use for ANY Frappe custom app.
---

# Frappe Operations Patterns

Generic production reliability patterns for Frappe apps — deduplication, cleanup, health monitoring, and admin controls.

## When to Use This Skill

- Adding deduplication to prevent duplicate events
- Setting up cleanup/scheduler jobs
- Building notification systems
- Implementing health monitoring
- Creating admin operational APIs

## Deduplication Pattern

```python
# services/deduplication_service.py
import frappe
from frappe.utils import add_to_date, now_datetime

def is_duplicate(
    event_type: str,
    record: str,
    window_seconds: int = 60
) -> bool:
    """Check if duplicate event exists within time window."""
    window_start = add_to_date(now_datetime(), seconds=-window_seconds)
    return bool(frappe.db.exists("[Event Log DocType]", {
        "event_type": event_type,
        "record": record,
        "creation": [">", window_start],
    }))
```

## Notification Service Pattern

```python
# services/notification_service.py
import frappe

def create_notification(
    event_type: str,
    record: str,
    title: str,
    message: str,
    route: str | None = None,
    priority: str = "Normal",
    owner_profile: str | None = None,
) -> dict:
    """Create notification with deduplication."""
    if is_duplicate(event_type, record):
        return {"success": False, "reason": "duplicate"}
    
    doc = frappe.get_doc({
        "doctype": "[Notification Event Log]",
        "event_type": event_type,
        "record": record,
        "owner_profile": owner_profile,
        "title": title,
        "message": message,
        "route": route,
        "priority": priority,
        "is_read": 0,
        "status": "Sent",
    })
    doc.insert(ignore_permissions=True)
    
    if _email_enabled(owner_profile):
        _queue_email(doc)
    
    frappe.db.commit()
    return {"success": True, "name": doc.name}


def _email_enabled(owner_profile: str) -> bool:
    prefs = frappe.db.get_value("[Notification Preference]",
        {"owner_profile": owner_profile},
        ["enable_email_notifications"],
        as_dict=True
    )
    return prefs and prefs.enable_email_notifications


def _queue_email(notification_doc):
    try:
        email = frappe.db.get_value("[Owner Profile]",
            notification_doc.owner_profile, "user")
        if email:
            frappe.sendmail(
                recipients=[email],
                subject=notification_doc.title,
                message=f"<p>{notification_doc.message}</p>",
            )
            frappe.db.set_value("[Notification Event Log]",
                notification_doc.name, "status", "Sent")
    except Exception as e:
        frappe.log_error(f"Email failed: {e}")
        frappe.db.set_value("[Notification Event Log]",
            notification_doc.name, "status", "Failed")
```

## Cleanup Service Pattern

```python
# services/cleanup_service.py
import frappe
from frappe.utils import add_to_date, now_datetime

def expire_stale_records():
    """Expire records inactive for N hours."""
    cutoff = add_to_date(now_datetime(), hours=-2)
    stale = frappe.get_all("[Session DocType]",
        filters={"status": "Active", "modified": ["<", cutoff]},
        pluck="name"
    )
    for name in stale:
        frappe.db.set_value("[Session DocType]", name, "status", "Expired")
    frappe.db.commit()
    return {"expired": len(stale)}


def cleanup_old_events():
    """Remove events older than N days."""
    cutoff = add_to_date(now_datetime(), days=-90)
    old = frappe.get_all("[Event DocType]",
        filters={"creation": ["<", cutoff]},
        pluck="name"
    )
    for name in old:
        frappe.delete_doc("[Event DocType]", name, ignore_permissions=True)
    frappe.db.commit()
    return {"deleted": len(old)}


def recompute_metadata():
    """Update latest timestamps on parent records."""
    records = frappe.get_all("[Parent DocType]", pluck="name")
    for name in records:
        latest = frappe.db.get_value("[Child DocType]",
            {"parent": name}, "creation", order_by="creation desc")
        frappe.db.set_value("[Parent DocType]", name, "latest_event_on", latest)
    frappe.db.commit()
    return {"updated": len(records)}


def health_check():
    """Check queue health."""
    failed = frappe.db.count("[Event Log]", {"status": "Failed"})
    queued = frappe.db.count("[Event Log]", {"status": "Queued"})
    
    status = "Healthy"
    if failed > 10 or queued > 200:
        status = "Critical"
    elif failed > 5 or queued > 100:
        status = "Warning"
    
    return {"status": status, "failed": failed, "queued": queued}
```

## Scheduler Events (hooks.py)

```python
scheduler_events = {
    "hourly": [
        "[APP_NAME].services.cleanup_service.expire_stale_records",
    ],
    "daily": [
        "[APP_NAME].services.cleanup_service.recompute_metadata",
        "[APP_NAME].services.cleanup_service.health_check",
    ],
    "weekly": [
        "[APP_NAME].services.cleanup_service.cleanup_old_events",
    ],
}
```

## Admin Operational API

```python
# api/operational_api.py
import frappe

@frappe.whitelist()
def get_health_summary() -> dict:
    """Get overall system health."""
    if not _is_admin():
        frappe.throw("Admin access required", frappe.PermissionError)
    
    from [APP_NAME].services.cleanup_service import health_check
    health = health_check()
    
    return {
        "status": health["status"],
        "metrics": health,
    }

@frappe.whitelist()
def get_failed_events() -> list[dict]:
    """Get failed events for retry."""
    if not _is_admin():
        frappe.throw("Admin access required")
    
    return frappe.get_all("[Event Log]",
        filters={"status": "Failed"},
        fields=["name", "event_type", "title", "status", "modified"],
        order_by="modified desc",
        limit=50,
    )

@frappe.whitelist(methods=["POST"])
def retry_event(event_id: str) -> dict:
    """Retry a failed event."""
    if not _is_admin():
        frappe.throw("Admin access required")
    
    doc = frappe.get_doc("[Event Log]", event_id)
    if doc.status != "Failed":
        return {"success": False, "error": "Not a failed event"}
    
    try:
        # Retry logic here
        doc.status = "Sent"
        doc.save(ignore_permissions=True)
        frappe.db.commit()
        return {"success": True}
    except Exception as e:
        return {"success": False, "error": str(e)}

@frappe.whitelist(methods=["POST"])
def run_maintenance(job_name: str) -> dict:
    """Run a maintenance job."""
    if not _is_admin():
        frappe.throw("Admin access required")
    
    jobs = {
        "expire_stale": "[APP_NAME].services.cleanup_service.expire_stale_records",
        "recompute": "[APP_NAME].services.cleanup_service.recompute_metadata",
        "health_check": "[APP_NAME].services.cleanup_service.health_check",
        "cleanup": "[APP_NAME].services.cleanup_service.cleanup_old_events",
    }
    
    if job_name not in jobs:
        return {"success": False, "error": f"Unknown job: {job_name}"}
    
    import importlib
    module_path, func_name = jobs[job_name].rsplit(".", 1)
    module = importlib.import_module(module_path)
    result = getattr(module, func_name)()
    return {"success": True, "result": result}

def _is_admin() -> bool:
    return frappe.session.user == "Administrator" or \
           "System Manager" in frappe.get_roles()
```

## Health Status Levels

| Status | Criteria |
|--------|----------|
| Healthy | No failures, low queue |
| Warning | 5-10 failures or 100+ queued |
| Critical | 10+ failures or 200+ queued |

## Testing

```python
import frappe
import unittest

class TestDeduplication(unittest.TestCase):
    def test_duplicate_detection(self):
        from [APP_NAME].services.deduplication_service import is_duplicate
        
        self.assertFalse(is_duplicate("Test", "REC-001"))
        
        frappe.get_doc({
            "doctype": "[Event Log]",
            "event_type": "Test",
            "record": "REC-001",
            "title": "Test",
        }).insert(ignore_permissions=True)
        
        self.assertTrue(is_duplicate("Test", "REC-001"))
```

## Best Practices

1. **Always deduplicate** — prevent spam from retries
2. **Use time windows** — don't block forever
3. **Log failures** — track status for debugging
4. **Admin controls** — let ops retry/cleanup manually
5. **Health checks** — monitor queue depth and failures
6. **Graceful degradation** — email failure shouldn't break core flow
