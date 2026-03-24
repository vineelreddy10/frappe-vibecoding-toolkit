#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
FORCE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/mcp-config.json"
OPENCODE_CONFIG="${HOME}/.config/opencode/opencode.json"
OH_MY_OPENCODE_CONFIG="${HOME}/.config/opencode/oh-my-opencode.json"

for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        --force) FORCE=true ;;
        --help)
            echo "Usage: $0 [--dry-run] [--force]"
            echo ""
            echo "Options:"
            echo "  --dry-run   Show what would be done without making changes"
            echo "  --force     Reinstall even if already installed"
            echo ""
            exit 0
            ;;
    esac
done

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing=()

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

    if ! command -v jq &>/dev/null; then
        log_warn "jq not found — installing via npm..."
        if [ "$DRY_RUN" = false ]; then
            npm install -g jq 2>/dev/null || log_warn "Could not install jq, using node for JSON parsing"
        fi
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing prerequisites:"
        for m in "${missing[@]}"; do
            echo "  - $m"
        done
        exit 1
    fi

    log_success "Prerequisites OK"
}

ensure_opencode_config() {
    log_info "Ensuring OpenCode config exists..."

    local config_dir="$(dirname "$OPENCODE_CONFIG")"
    mkdir -p "$config_dir"

    if [ ! -f "$OPENCODE_CONFIG" ]; then
        log_info "Creating opencode.json..."
        if [ "$DRY_RUN" = false ]; then
            cat > "$OPENCODE_CONFIG" << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [],
  "mcp": {}
}
EOF
        fi
        log_success "Created opencode.json"
    else
        log_success "opencode.json exists"
    fi
}

is_mcp_installed() {
    local name="$1"
    local type="$2"

    case $type in
        npm)
            local package="$3"
            npm list -g "$package" 2>/dev/null | grep -q "$package" && return 0
            ;;
        local|remote)
            if [ -f "$OPENCODE_CONFIG" ]; then
                node -e "
                    const fs = require('fs');
                    const config = JSON.parse(fs.readFileSync('$OPENCODE_CONFIG', 'utf8'));
                    const mcps = config.mcp || {};
                    process.exit(mcps['$name'] ? 0 : 1);
                " 2>/dev/null && return 0
            fi
            ;;
    esac

    return 1
}

add_mcp_to_config() {
    local name="$1"
    local config_json="$2"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would add MCP '$name' to opencode.json"
        return 0
    fi

    node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('$OPENCODE_CONFIG', 'utf8'));
        if (!config.mcp) config.mcp = {};
        config.mcp['$name'] = $config_json;
        config.mcp['$name'].enabled = true;
        fs.writeFileSync('$OPENCODE_CONFIG', JSON.stringify(config, null, 2));
    "
}

install_oh_my_opencode() {
    log_info "Installing oh-my-opencode plugin..."

    if is_mcp_installed "oh-my-opencode" "npm" "oh-my-opencode@latest" && [ "$FORCE" = false ]; then
        log_success "oh-my-opencode already installed"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would install oh-my-opencode"
        return 0
    fi

    npm install -g oh-my-opencode@latest 2>/dev/null || {
        log_warn "Global install failed, trying local..."
        mkdir -p ~/.config/opencode
        cd ~/.config/opencode
        npm install oh-my-opencode@latest
    }

    node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('$OPENCODE_CONFIG', 'utf8'));
        if (!config.plugin) config.plugin = [];
        if (!config.plugin.includes('oh-my-opencode@latest')) {
            config.plugin.push('oh-my-opencode@latest');
        }
        fs.writeFileSync('$OPENCODE_CONFIG', JSON.stringify(config, null, 2));
    "

    if [ ! -f "$OH_MY_OPENCODE_CONFIG" ]; then
        cat > "$OH_MY_OPENCODE_CONFIG" << 'EOF'
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/dev/assets/oh-my-opencode.schema.json",
  "agents": {
    "planner": { "model": "opencode/glm-4.7-free" },
    "executor": { "model": "opencode/glm-4.7-free" },
    "tester": { "model": "opencode/glm-4.7-free" },
    "debugger": { "model": "opencode/glm-4.7-free" }
  },
  "categories": {
    "visual-engineering": { "model": "opencode/glm-4.7-free" },
    "ultrabrain": { "model": "opencode/glm-4.7-free" },
    "deep": { "model": "opencode/glm-4.7-free" },
    "artistry": { "model": "opencode/glm-4.7-free" },
    "quick": { "model": "opencode/glm-4.7-free" },
    "unspecified-low": { "model": "opencode/glm-4.7-free" },
    "unspecified-high": { "model": "opencode/glm-4.7-free" },
    "writing": { "model": "opencode/glm-4.7-free" }
  }
}
EOF
    fi

    log_success "oh-my-opencode installed"
}

install_remote_mcp() {
    local name="$1"
    local url="$2"
    local headers="${3:-{}}"

    if is_mcp_installed "$name" "remote" && [ "$FORCE" = false ]; then
        log_success "MCP '$name' already configured"
        return 0
    fi

    local config_json="{\"type\":\"remote\",\"url\":\"$url\",\"headers\":$headers}"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure remote MCP '$name' at $url"
        return 0
    fi

    add_mcp_to_config "$name" "$config_json"
    log_success "Configured remote MCP: $name"
}

install_local_mcp() {
    local name="$1"
    shift
    local command_json="$1"

    if is_mcp_installed "$name" "local" && [ "$FORCE" = false ]; then
        log_success "MCP '$name' already configured"
        return 0
    fi

    local config_json="{\"type\":\"local\",\"command\":$command_json}"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure local MCP '$name'"
        return 0
    fi

    add_mcp_to_config "$name" "$config_json"
    log_success "Configured local MCP: $name"
}

main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║     Frappe Vibecoding Toolkit — MCP Installation         ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_warn "DRY RUN MODE — no changes will be made"
        echo ""
    fi

    check_prerequisites
    ensure_opencode_config

    echo ""
    log_info "Reading MCP configuration from ${CONFIG_FILE}..."

    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Config file not found: $CONFIG_FILE"
        exit 1
    fi

    local total=0
    local installed=0
    local skipped=0

    total=$(node -e "const c=JSON.parse(require('fs').readFileSync('$CONFIG_FILE','utf8'));console.log(c.mcps.length)")

    log_info "Found $total MCPs to process"
    echo ""

    install_oh_my_opencode
    echo ""

    node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));

        for (const mcp of config.mcps) {
            if (mcp.name === 'oh-my-opencode') continue;

            const parts = [];

            if (mcp.type === 'remote') {
                parts.push('remote');
                parts.push(mcp.url);
                parts.push(JSON.stringify(mcp.headers || {}));
            } else if (mcp.type === 'local') {
                parts.push('local');
                parts.push(JSON.stringify(mcp.command));
            } else if (mcp.type === 'npm') {
                parts.push('npm');
                parts.push(mcp.package);
            }

            console.log(mcp.name + '|' + parts.join('|'));
        }
    " 2>/dev/null | while IFS='|' read -r name type arg1 arg2; do
        log_info "Processing: $name ($type)"

        case $type in
            remote)
                install_remote_mcp "$name" "$arg1" "$arg2"
                ;;
            local)
                install_local_mcp "$name" "$arg1"
                ;;
            npm)
                log_success "MCP '$name' will use npx (no pre-install needed)"
                ;;
        esac

        echo ""
    done

    echo ""
    log_info "Running verification..."
    if [ -f "${SCRIPT_DIR}/verify-mcps.sh" ]; then
        bash "${SCRIPT_DIR}/verify-mcps.sh"
    else
        log_warn "Verification script not found, skipping"
    fi

    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete                  ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    log_success "All MCPs configured!"
    echo ""
    echo "Next steps:"
    echo "  1. Restart OpenCode to load new MCPs"
    echo "  2. Use 'setup-environment' prompt for full verification"
    echo ""
}

main "$@"
