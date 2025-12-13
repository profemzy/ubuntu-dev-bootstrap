#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Version configuration
RUBY_VERSION="3.4"

log_info() { echo -e "[INFO] $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Ruby installation failed. Check the error above."
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

# Install Ruby build dependencies for Ubuntu/Debian
log_info "Installing Ruby build dependencies..."
if ! sudo apt update; then
    log_error "Failed to update package lists"
    exit 1
fi

if ! sudo apt install -y build-essential libssl-dev libreadline-dev zlib1g-dev libyaml-dev libffi-dev libgdbm-dev; then
    log_error "Failed to install Ruby build dependencies"
    exit 1
fi

# Install Ruby version from mise config, if present.
if [ -f ~/.tool-versions ] && grep -q "ruby" ~/.tool-versions; then
    log_info "Installing Ruby from .tool-versions..."
    if ! mise install ruby; then
        log_error "Failed to install Ruby from .tool-versions"
        exit 1
    fi
elif [ -f mise.toml ] && grep -q "ruby" mise.toml; then
    log_info "Installing Ruby from mise.toml..."
    if ! mise install ruby; then
        log_error "Failed to install Ruby from mise.toml"
        exit 1
    fi
else
    log_info "Installing Ruby v${RUBY_VERSION}..."
    if ! mise install ruby@${RUBY_VERSION}; then
        log_error "Failed to install Ruby v${RUBY_VERSION}"
        exit 1
    fi
    if ! mise use -g ruby@${RUBY_VERSION}; then
        log_error "Failed to set Ruby v${RUBY_VERSION} as global default"
        exit 1
    fi
fi

log_success "Ruby installation complete!"
