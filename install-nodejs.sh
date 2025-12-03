#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Version configuration
NODE_VERSION="25"

log_info() { echo -e "[INFO] $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Node.js installation failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

# Check if mise is installed
if ! command -v mise &>/dev/null; then
    # Try the local bin path
    if [ -x "$HOME/.local/bin/mise" ]; then
        export PATH="$HOME/.local/bin:$PATH"
    else
        log_error "mise is not installed. Please run ./install-mise.sh first."
        exit 1
    fi
fi

# Install Node.js build dependencies for Ubuntu/Debian
log_info "Installing Node.js build dependencies..."
if ! sudo apt update; then
    log_error "Failed to update package lists"
    exit 1
fi

if ! sudo apt install -y build-essential libssl-dev zlib1g-dev; then
    log_error "Failed to install Node.js build dependencies"
    exit 1
fi

# Install nodejs version from .tool-versions or mise.toml if it exists
if [ -f ~/.tool-versions ] && grep -q "nodejs" ~/.tool-versions; then
    log_info "Installing Node.js from .tool-versions..."
    if ! mise install nodejs; then
        log_error "Failed to install Node.js from .tool-versions"
        exit 1
    fi
elif [ -f mise.toml ] && grep -q "node" mise.toml; then
    log_info "Installing Node.js from mise.toml..."
    if ! mise install node; then
        log_error "Failed to install Node.js from mise.toml"
        exit 1
    fi
else
    log_info "Installing Node.js v${NODE_VERSION}..."
    if ! mise install node@${NODE_VERSION}; then
        log_error "Failed to install Node.js v${NODE_VERSION}"
        exit 1
    fi
    if ! mise use -g node@${NODE_VERSION}; then
        log_error "Failed to set Node.js v${NODE_VERSION} as global default"
        exit 1
    fi
fi

log_success "Node.js installation complete!"
