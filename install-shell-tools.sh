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

# Track failures
declare -a FAILED_PACKAGES=()

cleanup() {
    local exit_code=$?
    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        echo ""
        log_warning "Some packages failed to install:"
        printf '  - %s\n' "${FAILED_PACKAGES[@]}"
    fi
    if [ $exit_code -ne 0 ]; then
        log_error "Shell tools installation encountered errors."
    fi
    exit $exit_code
}

trap cleanup EXIT

echo "Installing shell tools..."
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# ============================================================================
# JetBrainsMono Nerd Font - Required for starship prompt icons
# ============================================================================
echo "[1/4] JetBrainsMono Nerd Font"
if fc-list | grep -qi "JetBrainsMono.*Nerd"; then
    log_success "JetBrainsMono Nerd Font is already installed"
else
    log_info "Installing JetBrainsMono Nerd Font..."
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"

    if curl -fsSL -o "/tmp/JetBrainsMono.tar.xz" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"; then
        tar -xf "/tmp/JetBrainsMono.tar.xz" -C "$FONT_DIR"
        rm -f "/tmp/JetBrainsMono.tar.xz"
        fc-cache -f
        log_success "JetBrainsMono Nerd Font installed successfully"
        log_warning "Remember to set your terminal font to 'JetBrainsMono Nerd Font'"
    else
        log_error "Failed to download JetBrainsMono Nerd Font"
        FAILED_PACKAGES+=("JetBrainsMono Nerd Font")
    fi
fi

# ============================================================================
# starship - Cross-shell prompt
# ============================================================================
echo ""
echo "[2/4] starship - Cross-shell prompt"
if command_exists starship; then
    log_success "starship is already installed"
else
    log_info "Installing starship..."
    if curl -sS https://starship.rs/install.sh | sh -s -- -y; then
        log_success "starship installed successfully"
    else
        log_error "Failed to install starship"
        FAILED_PACKAGES+=("starship")
    fi
fi

# ============================================================================
# zoxide - Smarter cd command
# ============================================================================
echo ""
echo "[3/4] zoxide - Smarter cd command"
if command_exists zoxide; then
    log_success "zoxide is already installed"
else
    log_info "Installing zoxide..."
    if curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash; then
        log_success "zoxide installed successfully"
    else
        log_error "Failed to install zoxide"
        FAILED_PACKAGES+=("zoxide")
    fi
fi

# ============================================================================
# fzf - Fuzzy finder
# ============================================================================
echo ""
echo "[4/4] fzf - Fuzzy finder"
if command_exists fzf; then
    log_success "fzf is already installed"
else
    log_info "Installing fzf..."
    if sudo apt install -y fzf; then
        log_success "fzf installed successfully"
    else
        log_error "Failed to install fzf"
        FAILED_PACKAGES+=("fzf")
    fi
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "==================================="
echo "Shell tools installation complete!"
echo "==================================="
echo ""
echo "Installed tools:"
command_exists starship && echo "  - starship $(starship --version 2>/dev/null | head -1 || echo '')"
command_exists zoxide && echo "  - zoxide $(zoxide --version 2>/dev/null || echo '')"
command_exists fzf && echo "  - fzf $(fzf --version 2>/dev/null || echo '')"
fc-list | grep -qi "JetBrainsMono.*Nerd" && echo "  - JetBrainsMono Nerd Font"
echo ""
echo "Next steps:"
echo "  - Set your terminal font to 'JetBrainsMono Nerd Font' or 'JetBrainsMono NF'"
echo "  - Restart your terminal for changes to take effect"
