# Setup Guide

How to install and configure the Frappe Vibecoding Toolkit.

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Opencode | >=1.0.0 | AI coding assistant |
| oh-my-opencode | >=1.0.0 | Plugin system |
| Node.js | >=20 | Frontend builds |
| Python | >=3.11 | Frappe backend |
| Docker | >=24 | Deployment |
| Frappe Bench | >=5 | Development |

## Installation

### Step 1: Clone the Toolkit

```bash
cd ~/.config/opencode/skills
git clone https://github.com/vineelreddy10/frappe-vibecoding-toolkit.git frappe-vibecoding
```

### Step 2: Skills Auto-Discovered

Skills appear as:
- `frappe-backend`
- `frappe-frontend`
- `frappe-deployment`
- `frappe-testing`
- `frappe-operations`

### Step 3: Configure Opencode

Add to `~/.config/opencode/opencode.json`:

```json
{
  "plugin": ["oh-my-opencode@latest"],
  "mcp": {
    "shadcn": {
      "type": "local",
      "command": ["npx", "-y", "shadcn@latest", "mcp"],
      "enabled": true
    },
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp",
      "enabled": true
    },
    "playwright": {
      "type": "local",
      "command": ["npx", "-y", "@playwright/mcp"],
      "enabled": true
    }
  }
}
```

### Step 4: Configure Agents

Add to `~/.config/opencode/oh-my-opencode.json`:

```json
{
  "agents": {
    "planner": { "model": "opencode/glm-4.7-free" },
    "executor": { "model": "opencode/glm-4.7-free" },
    "tester": { "model": "opencode/glm-4.7-free" },
    "debugger": { "model": "opencode/glm-4.7-free" }
  }
}
```

### Step 5: Verify

```bash
opencode --list-skills
# Should show: frappe-backend, frappe-frontend, frappe-deployment, frappe-testing, frappe-operations
```

## Project Setup

### 1. Create Your Frappe App

```bash
bench new-app my_app
cd my_app
```

### 2. Copy Templates

```bash
# Copy SYSTEM_STATE template
cp ~/.config/opencode/skills/frappe-vibecoding/templates/SYSTEM_STATE_template.md ./SYSTEM_STATE.md

# Edit with your app specifics
vim SYSTEM_STATE.md
```

### 3. Create apps.json (for deployment)

```bash
cp ~/.config/opencode/skills/frappe-vibecoding/templates/apps-json-template.json ./apps.json

# Replace [ORG] and [APP_NAME]
sed -i 's/\[ORG\]/your-org/g' apps.json
sed -i 's/\[APP_NAME\]/my_app/g' apps.json
```

### 4. Start Using

In Opencode:
```
Use frappe-backend skill to create a DocType
Use build-feature prompt to build a notification system
```
