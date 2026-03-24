# Setup Environment Prompt

Use this prompt to bootstrap a complete Frappe Vibecoding Toolkit environment.

```
Set up the Frappe Vibecoding Toolkit for my development environment.

## What I Need

1. Install all required MCPs (Model Context Protocols)
2. Link the Frappe Vibecoding Toolkit plugin to OpenCode skills
3. Verify everything is working
4. Output ready-to-use status

## Steps to Execute

### Step 1: Detect Environment

Check:
- Node.js version (need >= 20)
- npm/npx available
- OpenCode installed
- ~/.config/opencode exists

### Step 2: Clone Plugin (if not present)

```bash
cd ~/.config/opencode/skills
git clone https://github.com/vineelreddy10/frappe-vibecoding-toolkit.git frappe-vibecoding
```

### Step 3: Run MCP Installation

```bash
cd ~/.config/opencode/skills/frappe-vibecoding
bash mcp/install-mcps.sh
```

This will:
- Install oh-my-opencode plugin
- Configure context7 MCP (remote documentation)
- Configure shadcn MCP (component discovery)
- Configure playwright MCP (browser automation)
- Configure filesystem MCP (file operations)

### Step 4: Verify Setup

```bash
cd ~/.config/opencode/skills/frappe-vibecoding
bash mcp/verify-mcps.sh
```

Expected output:
- ✓ Node.js >= 20
- ✓ npm available
- ✓ opencode.json exists
- ✓ oh-my-opencode plugin configured
- ✓ All MCPs configured
- ✓ Skills directory exists
- ✓ Frappe Vibecoding Toolkit found

### Step 5: Validate Skills

Check these skills are available in OpenCode:
- frappe-backend
- frappe-frontend
- frappe-deployment
- frappe-testing
- frappe-operations

### Step 6: Output Status

Print:
- Environment: [READY / NEEDS FIXES]
- MCPs: [X/Y configured]
- Skills: [X/Y available]
- Next steps: [list]

## If Issues Found

For each issue, provide:
1. What's wrong
2. How to fix (exact command)
3. Expected result after fix

## Final Output

```
╔═══════════════════════════════════════════════════════════╗
║           Frappe Vibecoding Toolkit — Ready!             ║
╚═══════════════════════════════════════════════════════════╝

Environment: ✅ READY
Node.js: v20.x.x
MCPs: 5/5 configured
Skills: 5/5 available

Quick Start:
  Use frappe-backend skill to create a DocType
  Use build-feature prompt to build a feature
  Use deployment-prompt to deploy

Documentation:
  ~/.config/opencode/skills/frappe-vibecoding/docs/setup-guide.md
  ~/.config/opencode/skills/frappe-vibecoding/docs/usage-guide.md
```
```
