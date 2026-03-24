#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/vineelreddy10/frappe-vibecoding-toolkit.git"
PLUGIN_DIR="${HOME}/.config/opencode/skills/frappe-vibecoding"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Frappe Vibecoding Toolkit — One Command Setup        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing=()

    if ! command -v git &>/dev/null; then
        missing+=("git")
    fi

    if ! command -v node &>/dev/null; then
        missing+=("node (Node.js >= 20)")
    else
        local node_version=$(node -v | sed 's/v//' | cut -d. -f1)
        if [ "$node_version" -lt 20 ]; then
            missing+=("node >= 20 (found v${node_version})")
        fi
    fi

    if ! command -v npm &>/dev/null && ! command -v npx &>/dev/null; then
        missing+=("npm or npx")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing prerequisites:"
        for m in "${missing[@]}"; do
            echo "  - $m"
        done
        echo ""
        echo "Install them first, then re-run this script."
        exit 1
    fi

    log_success "Prerequisites OK"
}

clone_plugin() {
    log_info "Setting up plugin directory..."
    mkdir -p "$(dirname "$PLUGIN_DIR")"

    if [ -d "$PLUGIN_DIR" ]; then
        log_warn "Plugin already exists at $PLUGIN_DIR"
        log_info "Pulling latest changes..."
        cd "$PLUGIN_DIR"
        git pull origin main 2>/dev/null || log_warn "Could not pull — using existing version"
    else
        log_info "Cloning plugin..."
        git clone "$REPO_URL" "$PLUGIN_DIR"
    fi

    log_success "Plugin ready at $PLUGIN_DIR"
}

install_mcps() {
    local install_script="${PLUGIN_DIR}/mcp/install-mcps.sh"

    if [ ! -f "$install_script" ]; then
        log_error "Install script not found: $install_script"
        exit 1
    fi

    log_info "Running MCP installation..."
    bash "$install_script"
}

verify_setup() {
    local verify_script="${PLUGIN_DIR}/mcp/verify-mcps.sh"

    if [ ! -f "$verify_script" ]; then
        log_warn "Verify script not found, skipping verification"
        return 0
    fi

    log_info "Running verification..."
    bash "$verify_script"
}

main() {
    check_prerequisites
    echo ""

    clone_plugin
    echo ""

    install_mcps
    echo ""

    verify_setup
    echo ""

    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                      Setup Complete!                     ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    log_success "Frappe Vibecoding Toolkit is ready!"
    echo ""
    echo "Installed:"
    echo "  • Plugin: $PLUGIN_DIR"
    echo "  • Skills: frappe-backend, frappe-frontend, frappe-deployment,"
    echo "            frappe-testing, frappe-operations"
    echo "  • Agents: planner, executor, tester, debugger"
    echo "  • MCPs:   oh-my-opencode, context7, shadcn, playwright, filesystem"
    echo ""
    echo "Quick Start:"
    echo "  1. Restart OpenCode"
    echo "  2. Use 'frappe-backend' skill to create a DocType"
    echo "  3. Use 'build-feature' prompt to build a feature"
    echo "  4. Use 'setup-environment' prompt for detailed verification"
    echo ""
    echo "Documentation:"
    echo "  $PLUGIN_DIR/docs/setup-guide.md"
    echo "  $PLUGIN_DIR/docs/usage-guide.md"
    echo ""
}

main "$@"
