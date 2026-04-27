#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/mise/shims:/usr/local/go/bin:$PATH"

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
        log_error "LazyVim installation failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

command_exists() {
    command -v "$1" &>/dev/null
}

# Check if directory is a symlink (managed by stow/dotfiles)
is_symlink() {
    [ -L "$1" ]
}

echo "Installing LazyVim..."
echo ""

# ============================================================================
# Step 1: Install Neovim (prerequisite)
# ============================================================================
echo "[1/2] Neovim (prerequisite for LazyVim)"
if command_exists nvim; then
    NVIM_CURRENT=$(nvim --version 2>/dev/null | head -1 || echo "unknown")
    log_success "Neovim is already installed: $NVIM_CURRENT"
else
    log_info "Installing Neovim..."
    NVIM_TAR="/tmp/nvim-linux64.tar.gz"
    if curl -fsSL -o "$NVIM_TAR" "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"; then
        sudo rm -rf /opt/nvim-linux64
        sudo tar -C /opt -xzf "$NVIM_TAR"
        rm -f "$NVIM_TAR"
        sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
        log_success "Neovim installed successfully"
    else
        rm -f "$NVIM_TAR"
        log_error "Failed to download Neovim"
        exit 1
    fi
fi

# ============================================================================
# Step 2: Install LazyVim starter config
# ============================================================================
echo ""
echo "[2/2] LazyVim configuration"

LAZYVIM_DIR="$HOME/.config/nvim"
LAZYVIM_STARTER="https://github.com/LazyVim/starter"

# Check if nvim config directory already exists
if [ -d "$LAZYVIM_DIR" ]; then
    if is_symlink "$LAZYVIM_DIR"; then
        # Managed by stow/dotfiles - skip
        log_warning "~/.config/nvim is a symlink (managed by stow/dotfiles)"
        log_info "Skipping LazyVim install to preserve your dotfiles-managed Neovim config"
        exit 0
    fi

    # Check if it's already a LazyVim install
    if [ -f "$LAZYVIM_DIR/init.lua" ]; then
        if grep -q "LazyVim" "$LAZYVIM_DIR/init.lua" 2>/dev/null; then
            log_success "LazyVim configuration already exists"
            exit 0
        fi
    fi

    # Existing non-LazyVim config
    BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
    log_warning "Existing Neovim config found, backing up to $(basename "$BACKUP_DIR")"
    mv "$LAZYVIM_DIR" "$BACKUP_DIR"
fi

log_info "Cloning LazyVim starter..."
if git clone "$LAZYVIM_STARTER" "$LAZYVIM_DIR"; then
    # Remove the .git directory so the user can version their own config
    rm -rf "$LAZYVIM_DIR/.git"
    log_success "LazyVim installed successfully"
else
    log_error "Failed to clone LazyVim starter"
    # Restore backup if clone failed
    if [ -n "${BACKUP_DIR:-}" ] && [ -d "$BACKUP_DIR" ]; then
        mv "$BACKUP_DIR" "$LAZYVIM_DIR"
        log_info "Restored previous Neovim config from backup"
    fi
    exit 1
fi

echo ""
echo "LazyVim installation complete!"
log_info "Run 'nvim' to start LazyVim (plugins will auto-install on first launch)"
