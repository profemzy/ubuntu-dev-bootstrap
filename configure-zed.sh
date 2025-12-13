#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "[INFO] $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

ENV_DIR="$HOME/.config/environment.d"
ENV_FILE="$ENV_DIR/zed.conf"
DESIRED_LINE="ZED_ALLOW_EMULATED_GPU=1"

log_info "Ensuring Zed runs on systems without native Vulkan..."

mkdir -p "$ENV_DIR"

if [ -f "$ENV_FILE" ]; then
    if grep -qx "$DESIRED_LINE" "$ENV_FILE"; then
        log_success "ZED_ALLOW_EMULATED_GPU is already set"
        exit 0
    fi

    if grep -q '^ZED_ALLOW_EMULATED_GPU=' "$ENV_FILE"; then
        log_warning "Updating existing ZED_ALLOW_EMULATED_GPU entry"
        sed -i 's/^ZED_ALLOW_EMULATED_GPU=.*/ZED_ALLOW_EMULATED_GPU=1/' "$ENV_FILE"
    else
        log_warning "Appending ZED_ALLOW_EMULATED_GPU to existing config"
        printf '\n%s\n' "$DESIRED_LINE" >> "$ENV_FILE"
    fi
else
    log_info "Creating $ENV_FILE"
    cat <<EOF > "$ENV_FILE"
# Force Zed to allow emulated GPU backends
$DESIRED_LINE
EOF
fi

log_success "ZED_ALLOW_EMULATED_GPU=1 configured"
log_info "Log out/in or reboot for the environment.d change to apply everywhere"
