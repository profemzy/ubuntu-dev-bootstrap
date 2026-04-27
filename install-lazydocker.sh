#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/mise/shims:/usr/local/go/bin:$PATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "[INFO] $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Lazydocker installation failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

command_exists() {
    command -v "$1" &>/dev/null
}

echo "Installing Lazydocker..."
echo ""

if command_exists lazydocker; then
    log_success "Lazydocker is already installed"
else
    log_info "Fetching latest Lazydocker version..."
    LAZYDOCKER_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    if [ -z "$LAZYDOCKER_VERSION" ]; then
        log_error "Failed to get Lazydocker version"
        exit 1
    fi

    LAZYDOCKER_TAR="lazydocker_${LAZYDOCKER_VERSION#v}_Linux_x86_64.tar.gz"
    log_info "Downloading Lazydocker ${LAZYDOCKER_VERSION}..."
    if curl -fsSL -o "/tmp/${LAZYDOCKER_TAR}" "https://github.com/jesseduffield/lazydocker/releases/download/${LAZYDOCKER_VERSION}/${LAZYDOCKER_TAR}"; then
        tar -xzf "/tmp/${LAZYDOCKER_TAR}" -C /tmp
        sudo mv /tmp/lazydocker /usr/local/bin/lazydocker
        sudo chmod +x /usr/local/bin/lazydocker
        rm -f "/tmp/${LAZYDOCKER_TAR}"
        log_success "Lazydocker ${LAZYDOCKER_VERSION} installed successfully"
    else
        rm -f "/tmp/${LAZYDOCKER_TAR}"
        log_error "Failed to download Lazydocker"
        exit 1
    fi
fi

echo ""
echo "Lazydocker installation complete!"
command_exists lazydocker && log_info "Lazydocker $(lazydocker --version 2>/dev/null | head -1 || echo '')"
