# Create DocType Prompt

Use this prompt to create a new Frappe DocType.

```
Create a DocType named [DOCTYPE_NAME] in module [MODULE_NAME] for app [APP_NAME].

## Fields
| Fieldname | Type | Label | Options | Required |
|-----------|------|-------|---------|----------|
| [fieldname] | [fieldtype] | [Label] | [options] | [yes/no] |
| [fieldname] | [fieldtype] | [Label] | [options] | [yes/no] |

## Relationships
- Links to: [OtherDocType] via [fieldname]
- Child table: [ChildDocType] in [fieldname]

## Naming
- Pattern: [naming_series / field / hash / prompt]
- Example: [EXAMPLE-001]

## Permissions
| Role | Read | Write | Create | Delete |
|------|------|-------|--------|--------|
| [Role1] | ✅ | ✅ | ✅ | ✅ |
| [Role2] | ✅ | ✅ | ✅ | ❌ |

## Status Field
Options: [Status1, Status2, Status3]
Default: [Default]

## Create
- DocType JSON
- Python controller with validate/before_insert/on_update hooks
- Test file skeleton
```
