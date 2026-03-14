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
        log_error "uv installation failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

# Install uv (Python package manager)
if command -v uv &>/dev/null; then
    log_success "uv is already installed"
    uv --version
    exit 0
fi

log_info "Installing uv (extremely fast Python package manager)..."
# Official installer automatically fetches latest version
if ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
    log_error "Failed to install uv"
    exit 1
fi

# Source the env for current session
export PATH="$HOME/.local/bin:$PATH"

log_success "uv installed successfully"
echo ""
uv --version
echo ""
echo "uv has been installed to ~/.local/bin"
echo ""
echo "Usage examples:"
echo "  uv python install 3.12    # Install Python 3.12"
echo "  uv venv                   # Create virtual environment"
echo "  uv pip install package    # Install packages"
echo "  uv run script.py          # Run Python script"
echo "  uv self update            # Update uv to latest version"
