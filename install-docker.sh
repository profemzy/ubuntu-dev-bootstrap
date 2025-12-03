#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "[INFO] $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Docker installation failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

# Check if Docker is already installed
if command -v docker &>/dev/null; then
    log_success "Docker is already installed"
    docker --version
    exit 0
fi

# Remove old versions (if any)
log_info "Removing old Docker versions (if any)..."
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Install prerequisites
log_info "Installing prerequisites..."
if ! sudo apt update; then
    log_error "Failed to update package lists"
    exit 1
fi

if ! sudo apt install -y ca-certificates curl gnupg; then
    log_error "Failed to install prerequisites"
    exit 1
fi

# Add Docker's official GPG key
log_info "Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings

if [ -f /etc/apt/keyrings/docker.gpg ]; then
    log_info "Docker GPG key already exists, removing for fresh install..."
    sudo rm /etc/apt/keyrings/docker.gpg
fi

if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
    log_error "Failed to add Docker GPG key"
    exit 1
fi

sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
# Note: Pop!_OS uses UBUNTU_CODENAME from /etc/os-release
log_info "Adding Docker repository..."
UBUNTU_CODENAME=$(. /etc/os-release && echo "$UBUNTU_CODENAME")

if [ -z "$UBUNTU_CODENAME" ]; then
    # Fallback for Pop!_OS if UBUNTU_CODENAME is not set
    UBUNTU_CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
fi

if [ -z "$UBUNTU_CODENAME" ]; then
    log_error "Could not determine Ubuntu codename"
    exit 1
fi

log_info "Using Ubuntu codename: $UBUNTU_CODENAME"

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker CE
log_info "Installing Docker CE..."
if ! sudo apt update; then
    log_error "Failed to update package lists after adding Docker repo"
    exit 1
fi

if ! sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    log_error "Failed to install Docker CE"
    exit 1
fi

# Add user to docker group
log_info "Adding $USER to docker group..."
if ! sudo usermod -aG docker "$USER"; then
    log_error "Failed to add user to docker group"
    exit 1
fi

# Start and enable Docker service
log_info "Starting Docker service..."
if ! sudo systemctl start docker; then
    log_error "Failed to start Docker service"
    exit 1
fi

if ! sudo systemctl enable docker; then
    log_error "Failed to enable Docker service"
    exit 1
fi

log_success "Docker CE installation complete!"
docker --version
echo ""
log_warning "IMPORTANT: You need to log out and log back in for docker group membership to take effect."
log_info "After logging back in, you can run 'docker run hello-world' to verify the installation."
