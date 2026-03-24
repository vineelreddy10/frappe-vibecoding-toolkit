#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OPENCODE_CONFIG="${HOME}/.config/opencode/opencode.json"
OH_MY_OPENCODE_CONFIG="${HOME}/.config/opencode/oh-my-opencode.json"
SKILLS_DIR="${HOME}/.config/opencode/skills"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

PASS=0
FAIL=0
WARN=0

check_pass() { ((PASS++)); log_success "$1"; }
check_fail() { ((FAIL++)); log_error "$1"; }
check_warn() { ((WARN++)); log_warn "$1"; }

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Frappe Vibecoding Toolkit — Environment Verify       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

log_info "Checking system prerequisites..."
echo ""

if command -v node &>/dev/null; then
    node_version=$(node -v)
    node_major=$(echo "$node_version" | sed 's/v//' | cut -d. -f1)
    if [ "$node_major" -ge 20 ]; then
        check_pass "Node.js $node_version (>= 20)"
    else
        check_fail "Node.js $node_version (need >= 20)"
    fi
else
    check_fail "Node.js not found"
fi

if command -v npm &>/dev/null; then
    check_pass "npm $(npm -v)"
else
    check_fail "npm not found"
fi

if command -v npx &>/dev/null; then
    check_pass "npx available"
else
    check_warn "npx not found (will use npm)"
fi

echo ""
log_info "Checking OpenCode configuration..."
echo ""

if [ -f "$OPENCODE_CONFIG" ]; then
    check_pass "opencode.json exists"
else
    check_fail "opencode.json not found at $OPENCODE_CONFIG"
fi

if [ -f "$OH_MY_OPENCODE_CONFIG" ]; then
    check_pass "oh-my-opencode.json exists"
else
    check_warn "oh-my-opencode.json not found (will be created on install)"
fi

echo ""
log_info "Checking MCP configuration..."
echo ""

if [ -f "$OPENCODE_CONFIG" ]; then
    node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('$OPENCODE_CONFIG', 'utf8'));
        const mcps = config.mcp || {};
        const plugins = config.plugin || [];

        let ok = 0;
        let fail = 0;

        if (plugins.includes('oh-my-opencode@latest')) {
            console.log('OK|oh-my-opencode plugin configured');
            ok++;
        } else {
            console.log('WARN|oh-my-opencode plugin not in plugin list');
        }

        const expected = ['context7', 'shadcn', 'playwright', 'filesystem'];
        for (const name of expected) {
            if (mcps[name]) {
                console.log('OK|MCP ' + name + ' configured');
                ok++;
            } else {
                console.log('WARN|MCP ' + name + ' not configured');
            }
        }

        process.exit(fail > 0 ? 1 : 0);
    " 2>/dev/null | while IFS='|' read -r status msg; do
        case $status in
            OK) check_pass "$msg" ;;
            WARN) check_warn "$msg" ;;
            FAIL) check_fail "$msg" ;;
        esac
    done
else
    check_warn "Cannot verify MCPs — opencode.json not found"
fi

echo ""
log_info "Checking skills installation..."
echo ""

if [ -d "$SKILLS_DIR" ]; then
    check_pass "Skills directory exists"

    toolkit_dir=$(find "$SKILLS_DIR" -maxdepth 1 -type d -name "*vibecoding*" -o -name "*frappe*" 2>/dev/null | head -1)
    if [ -n "$toolkit_dir" ]; then
        check_pass "Frappe Vibecoding Toolkit found"
    else
        check_warn "Frappe Vibecoding Toolkit not found in skills"
    fi
else
    check_warn "Skills directory not found"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "  ${GREEN}Passed:${NC}  $PASS"
echo -e "  ${YELLOW}Warnings:${NC} $WARN"
echo -e "  ${RED}Failed:${NC}  $FAIL"
echo ""

if [ $FAIL -gt 0 ]; then
    log_error "Verification FAILED — run install-mcps.sh to fix"
    exit 1
elif [ $WARN -gt 0 ]; then
    log_warn "Verification passed with warnings"
    exit 0
else
    log_success "All checks passed — environment ready!"
    exit 0
fi
