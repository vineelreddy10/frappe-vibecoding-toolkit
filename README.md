# Frappe Vibecoding Toolkit

A generic Opencode plugin for building ANY Frappe custom app — ERP, SaaS, HES, internal tools — with best practices baked in.

## What This Is

**NOT** a ScanifyMe-specific plugin.  
**NOT** a project-specific toolkit.  
**IS** a generic framework for Frappe development.

## What's Included

### Skills (5)

| Skill | Purpose |
|-------|---------|
| `frappe-backend` | DocType, Safe List API, RBAC, services, hooks |
| `frappe-frontend` | React routing, shadcn, metadata-driven UI |
| `frappe-deployment` | Docker, VPS deploy, CI/CD, asset sync |
| `frappe-testing` | Playwright E2E, unit tests, RBAC |
| `frappe-operations` | Deduplication, cleanup, health monitoring |

### Agents (4)

| Agent | Purpose |
|-------|---------|
| `planner` | Break complex tasks into phases |
| `executor` | Execute step-by-step with validation |
| `tester` | Exhaustive testing (unit, RBAC, E2E) |
| `debugger` | Root cause analysis, regression prevention |

### Prompts (7)

| Prompt | Purpose |
|--------|---------|
| `build-feature` | Build a complete feature |
| `create-doctype` | Create a DocType |
| `create-api` | Create API endpoints |
| `create-frontend-page` | Create React pages |
| `testing-prompt` | Write comprehensive tests |
| `deployment-prompt` | Deploy to production |
| `debugging-prompt` | Debug issues |

### Templates (4)

| Template | Purpose |
|----------|---------|
| `SYSTEM_STATE_template.md` | Track operational state |
| `project-structure.md` | Standard app layout |
| `apps-json-template.json` | Docker deployment config |
| `deployment-checklist.md` | Pre/post deploy checks |

## ⚡ One Command Setup

```bash
git clone https://github.com/vineelreddy10/frappe-vibecoding-toolkit.git
cd frappe-vibecoding-toolkit
./install.sh
```

This automatically:
- Installs plugin to `~/.config/opencode/skills/`
- Configures all MCPs (oh-my-opencode, context7, shadcn, playwright, filesystem)
- Sets up opencode.json and oh-my-opencode.json
- Verifies environment

### Alternative: Via Opencode Prompt

```
Use setup-environment prompt to bootstrap my environment
```

### Manual Install

```bash
cd ~/.config/opencode/skills
git clone https://github.com/vineelreddy10/frappe-vibecoding-toolkit.git frappe-vibecoding
cd frappe-vibecoding
bash mcp/install-mcps.sh
```

### Verify Installation

```bash
bash mcp/verify-mcps.sh
```

### Use

```
Use frappe-backend skill to create a DocType
Use build-feature prompt to build a notification system
Use deployment-prompt to deploy to my VPS
```

### Customize

Replace `[PLACEHOLDERS]` in prompts and templates with your app specifics.

## Placeholder System

All prompts and templates use `[PLACEHOLDERS]`:

| Placeholder | Replace With |
|-------------|--------------|
| `[APP_NAME]` | Your app name (e.g., `my_erp`) |
| `[MODULE]` | Module name (e.g., `items`) |
| `[DOCTYPE]` | DocType name (e.g., `Customer`) |
| `[VPS_IP]` | Your server IP |
| `[SITE_NAME]` | Your site name |
| `[ORG]` | Your GitHub org |

## Architecture Rules

1. **Routes**: All React under `/frontend/*`
2. **APIs**: All under `/api/*`
3. **RBAC**: Owner sees own, Admin sees all, Guest denied
4. **Filters**: Dict format, not JSON string
5. **Numbers**: Use `safeToFixed()`, never `.toFixed()`
6. **Public**: Never expose owner email/phone

## Works For

- ✅ ERP apps
- ✅ SaaS products
- ✅ HES systems
- ✅ Internal tools
- ✅ Any custom Frappe app

### MCPs (5)

| MCP | Type | Purpose |
|-----|------|---------|
| `oh-my-opencode` | npm | Plugin system with agents and categories |
| `context7` | remote | Real-time documentation lookup |
| `shadcn` | local | shadcn/ui component discovery |
| `playwright` | local | Browser automation for E2E testing |
| `filesystem` | local | File system operations |

## File Structure

```
frappe-vibecoding-toolkit/
├── README.md
├── LICENSE
├── install.sh                      ← One-command setup
├── plugin.json
├── mcp/
│   ├── mcp-config.json             ← MCP definitions
│   ├── mcp-config.schema.json      ← Config schema
│   ├── install-mcps.sh             ← MCP installer
│   └── verify-mcps.sh              ← Environment verifier
├── skills/
│   ├── frappe-backend.md
│   ├── frappe-frontend.md
│   ├── frappe-deployment.md
│   ├── frappe-testing.md
│   └── frappe-operations.md
├── agents/
│   ├── planner.md
│   ├── executor.md
│   ├── tester.md
│   └── debugger.md
├── prompts/
│   ├── setup-environment.md        ← Bootstrap prompt
│   ├── build-feature.md
│   ├── create-doctype.md
│   ├── create-api.md
│   ├── create-frontend-page.md
│   ├── testing-prompt.md
│   ├── deployment-prompt.md
│   └── debugging-prompt.md
├── templates/
│   ├── SYSTEM_STATE_template.md
│   ├── project-structure.md
│   ├── apps-json-template.json
│   └── deployment-checklist.md
└── docs/
    ├── setup-guide.md
    ├── usage-guide.md
    └── best-practices.md
```

## Requirements

| Tool | Version |
|------|---------|
| Opencode | >=1.0.0 |
| oh-my-opencode | >=1.0.0 |
| Node.js | >=20 |
| Python | >=3.11 |
| Docker | >=24 |

## Extending

### Add Custom Skills

Create `.md` file in `skills/` directory.

### Add Custom Agents

1. Create `.md` in `agents/`
2. Add to `oh-my-opencode.json`

### Add Custom Prompts

Create `.md` in `prompts/` with `[PLACEHOLDERS]`.

## License

MIT

## Repository

https://github.com/vineelreddy10/frappe-vibecoding-toolkit
