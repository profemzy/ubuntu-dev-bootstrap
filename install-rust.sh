#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/mise/shims:/usr/local/go/bin:$PATH"

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
        log_error "Rust installation failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

# Install Rust via rustup (official installer)
if command -v rustc &>/dev/null; then
    log_success "Rust is already installed"
    rustc --version
    cargo --version
    exit 0
fi

log_info "Installing Rust via rustup (official installer)..."
# rustup automatically installs the latest stable version
if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
    log_error "Failed to install Rust"
    exit 1
fi

# Source cargo env for current session
source "$HOME/.cargo/env"

log_success "Rust installed successfully"
echo ""
rustc --version
cargo --version
echo ""
echo "Rust has been installed to ~/.cargo"
echo ""
echo "Useful commands:"
echo "  rustup update           # Update Rust to latest stable"
echo "  rustup show             # Show installed toolchains"
echo "  cargo new project       # Create new project"
echo "  cargo build             # Build project"
echo "  cargo run               # Run project"
echo ""
echo "Restart your shell or run: source ~/.cargo/env"
