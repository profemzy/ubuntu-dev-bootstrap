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
        log_error "Go installation failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

# Install Go
if command -v go &>/dev/null; then
    log_success "Go is already installed"
    go version
    exit 0
fi

# Fetch the latest stable Go version from the official API
log_info "Fetching latest Go version..."
GO_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1)

if [ -z "$GO_VERSION" ]; then
    log_error "Failed to fetch latest Go version"
    exit 1
fi

log_info "Latest Go version: ${GO_VERSION}"

GO_TAR="${GO_VERSION}.linux-amd64.tar.gz"
DOWNLOAD_URL="https://go.dev/dl/${GO_TAR}"

log_info "Downloading ${GO_TAR}..."
if ! curl -fsSL -o "/tmp/${GO_TAR}" "$DOWNLOAD_URL"; then
    log_error "Failed to download Go"
    exit 1
fi

log_info "Installing Go to /usr/local/go..."
# Remove any existing Go installation
sudo rm -rf /usr/local/go

if ! sudo tar -C /usr/local -xzf "/tmp/${GO_TAR}"; then
    log_error "Failed to extract Go"
    exit 1
fi

rm -f "/tmp/${GO_TAR}"

# Add to PATH if not already there
if ! grep -q '/usr/local/go/bin' ~/.profile 2>/dev/null; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
    log_info "Added Go to PATH in ~/.profile"
fi

# Also add GOPATH bin for installed Go tools
if ! grep -q 'GOPATH' ~/.profile 2>/dev/null; then
    echo 'export GOPATH=$HOME/go' >> ~/.profile
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.profile
    log_info "Added GOPATH to ~/.profile"
fi

# Export for current session
export PATH=$PATH:/usr/local/go/bin

log_success "Go installed successfully"
echo ""
go version
echo ""
echo "Go has been installed to /usr/local/go"
echo "GOPATH will be set to ~/go"
echo ""
echo "Useful commands:"
echo "  go mod init project     # Initialize new module"
echo "  go build                # Build project"
echo "  go run main.go          # Run program"
echo "  go get package          # Install package"
echo "  go install tool@latest  # Install Go tool"
echo ""
echo "Restart your shell or run: source ~/.profile"
