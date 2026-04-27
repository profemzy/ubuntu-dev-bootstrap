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
        log_error "Lazygit installation failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

command_exists() {
    command -v "$1" &>/dev/null
}

echo "Installing Lazygit..."
echo ""

if command_exists lazygit; then
    log_success "Lazygit is already installed"
else
    log_info "Fetching latest Lazygit version..."
    LAZYGIT_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    if [ -z "$LAZYGIT_VERSION" ]; then
        log_error "Failed to get Lazygit version"
        exit 1
    fi

    LAZYGIT_TAR="lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz"
    log_info "Downloading Lazygit ${LAZYGIT_VERSION}..."
    if curl -fsSL -o "/tmp/${LAZYGIT_TAR}" "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/${LAZYGIT_TAR}"; then
        tar -xzf "/tmp/${LAZYGIT_TAR}" -C /tmp
        sudo mv /tmp/lazygit /usr/local/bin/lazygit
        sudo chmod +x /usr/local/bin/lazygit
        rm -f "/tmp/${LAZYGIT_TAR}"
        log_success "Lazygit ${LAZYGIT_VERSION} installed successfully"
    else
        rm -f "/tmp/${LAZYGIT_TAR}"
        log_error "Failed to download Lazygit"
        exit 1
    fi
fi

echo ""
echo "Lazygit installation complete!"
command_exists lazygit && log_info "Lazygit $(lazygit --version 2>/dev/null | head -1 || echo '')"
