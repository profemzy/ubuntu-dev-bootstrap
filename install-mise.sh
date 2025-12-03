#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "[INFO] $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "mise installation failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

# Install mise (modern replacement for asdf)
# mise is faster and more user-friendly than asdf

if command -v mise &>/dev/null; then
    log_success "mise is already installed"
    exit 0
fi

# Check if mise exists in local bin
if [ -x "$HOME/.local/bin/mise" ]; then
    log_success "mise is already installed in ~/.local/bin"
    exit 0
fi

# Check curl is available
if ! command -v curl &>/dev/null; then
    log_error "curl is required but not installed"
    exit 1
fi

log_info "Installing mise..."
if ! curl -fsSL https://mise.run | sh; then
    log_error "Failed to download and install mise"
    exit 1
fi

# Verify installation
if [ ! -x "$HOME/.local/bin/mise" ]; then
    log_error "mise binary not found after installation"
    exit 1
fi

# Add mise to shell configs if not already present
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"

if [ -f "$BASHRC" ] && ! grep -q 'mise activate' "$BASHRC"; then
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> "$BASHRC"
    log_info "Added mise activation to .bashrc"
fi

if [ -f "$ZSHRC" ] && ! grep -q 'mise activate' "$ZSHRC"; then
    echo 'eval "$(~/.local/bin/mise activate zsh)"' >> "$ZSHRC"
    log_info "Added mise activation to .zshrc"
fi

log_success "mise installation complete!"
log_info "Note: Restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to use mise"
