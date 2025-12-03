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
        log_error "Fastfetch installation failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

# Install fastfetch
if command -v fastfetch &>/dev/null; then
    log_success "Fastfetch is already installed"
    exit 0
fi

log_info "Adding fastfetch PPA..."
if ! sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch; then
    log_error "Failed to add fastfetch PPA"
    exit 1
fi

log_info "Updating package lists..."
if ! sudo apt update; then
    log_error "Failed to update package lists"
    exit 1
fi

log_info "Installing fastfetch..."
if ! sudo apt install -y fastfetch; then
    log_error "Failed to install fastfetch"
    exit 1
fi

log_success "Fastfetch installed successfully"
echo ""
fastfetch --version
