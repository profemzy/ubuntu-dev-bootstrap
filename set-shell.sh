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
        log_error "Shell configuration failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

# Check if zsh is installed
if ! command -v zsh &>/dev/null; then
    log_error "Zsh is not installed. Please run ./install-zsh.sh first."
    exit 1
fi

# Get the path to zsh
ZSH_PATH=$(which zsh)

# Check if zsh is already the default shell
if [ "$SHELL" = "$ZSH_PATH" ]; then
    log_success "Zsh is already your default shell"
    exit 0
fi

# Add zsh to /etc/shells if not already there
if ! grep -q "^$ZSH_PATH$" /etc/shells; then
    log_info "Adding zsh to /etc/shells..."
    if ! echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null; then
        log_error "Failed to add zsh to /etc/shells"
        exit 1
    fi
fi

# Change the default shell to zsh
log_info "Changing default shell to zsh..."
if ! chsh -s "$ZSH_PATH"; then
    log_error "Failed to change default shell to zsh"
    exit 1
fi

log_success "Default shell changed to zsh"
log_info "Please log out and log back in for the change to take effect"
