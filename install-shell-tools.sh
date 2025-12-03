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
# fzf - Fuzzy finder (install from GitHub for latest version with --zsh support)
# ============================================================================
echo ""
echo "[4/4] fzf - Fuzzy finder"

# Check if fzf exists and supports --zsh flag (requires 0.48+)
fzf_needs_upgrade() {
    if ! command_exists fzf; then
        return 0  # needs install
    fi
    # Check if --zsh is supported
    if fzf --zsh &>/dev/null; then
        return 1  # no upgrade needed
    else
        return 0  # needs upgrade
    fi
}

if ! fzf_needs_upgrade; then
    log_success "fzf is already installed (with --zsh support)"
else
    if command_exists fzf; then
        log_warning "fzf installed but outdated (missing --zsh support), upgrading..."
        # Remove old apt version if present
        sudo apt remove -y fzf 2>/dev/null || true
    fi
    log_info "Installing fzf from GitHub (latest version)..."
    FZF_VERSION=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    if [ -n "$FZF_VERSION" ]; then
        FZF_TAR="fzf-${FZF_VERSION}-linux_amd64.tar.gz"
        if curl -fsSL -o "/tmp/${FZF_TAR}" "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/${FZF_TAR}"; then
            tar -xzf "/tmp/${FZF_TAR}" -C /tmp
            sudo mv /tmp/fzf /usr/local/bin/fzf
            sudo chmod +x /usr/local/bin/fzf
            rm -f "/tmp/${FZF_TAR}"
            log_success "fzf ${FZF_VERSION} installed successfully"
        else
            log_error "Failed to download fzf"
            FAILED_PACKAGES+=("fzf")
        fi
    else
        log_error "Failed to get fzf version"
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
