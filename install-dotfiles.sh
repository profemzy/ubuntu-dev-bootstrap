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
        log_error "Dotfiles installation failed. Check the error above."
    fi
    exit $exit_code
}

trap cleanup EXIT

REPO_URL="git@github.com:profemzy/dotfiles.git"
REPO_NAME="dotfiles"
DOTFILES_DIR="$HOME/$REPO_NAME"

# Check if stow is installed
if ! command -v stow &>/dev/null; then
    log_error "stow is not installed. Please run ./install-stow.sh first."
    exit 1
fi

cd "$HOME" || exit 1

# Check if the repository already exists
if [ -d "$DOTFILES_DIR" ]; then
    log_info "Repository '$REPO_NAME' already exists. Skipping clone"
else
    log_info "Cloning dotfiles repository..."
    if ! git clone "$REPO_URL" "$DOTFILES_DIR"; then
        log_error "Failed to clone the dotfiles repository"
        log_info "Make sure you have SSH keys configured for GitHub"
        exit 1
    fi
fi

log_info "Preparing configs..."

if [ ! -f "$HOME/.zprofile" ]; then
    log_info "Creating .zprofile to load .profile for zsh login shells"
    cat > "$HOME/.zprofile" <<'EOF'
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
EOF
elif ! grep -Fqx '[ -f "$HOME/.profile" ] && . "$HOME/.profile"' "$HOME/.zprofile"; then
    log_info "Adding .profile loading to existing .zprofile"
    printf '\n%s\n' '[ -f "$HOME/.profile" ] && . "$HOME/.profile"' >> "$HOME/.zprofile"
fi

if [ -e ~/.zshrc ] && [ ! -L ~/.zshrc ]; then
    backup_path="$HOME/.zshrc.pre-dotfiles.$(date +%Y%m%d%H%M%S)"
    log_info "Backing up existing .zshrc to $(basename "$backup_path")"
    mv ~/.zshrc "$backup_path"
fi

# Only remove configs if they're not already symlinks to dotfiles
if [ -e ~/.config/nvim ] && [ ! -L ~/.config/nvim ]; then
    log_info "Removing old nvim config (not a symlink)"
    rm -rf ~/.config/nvim
fi

if [ -e ~/.config/starship.toml ] && [ ! -L ~/.config/starship.toml ]; then
    log_info "Removing old starship config (not a symlink)"
    rm -rf ~/.config/starship.toml
fi

# Always remove cache/data directories (should be regenerated)
log_info "Cleaning caches..."
rm -rf ~/.local/share/nvim/ ~/.cache/nvim/

cd "$DOTFILES_DIR" || exit 1

log_info "Applying dotfiles with stow..."

# Apply each stow package with error handling
# Note: Skipping ghostty and hyprland for Pop!_OS
for pkg in zshrc nvim starship; do
    if [ -d "$pkg" ]; then
        if ! stow "$pkg"; then
            log_error "Failed to stow: $pkg"
            exit 1
        fi
        log_success "Applied: $pkg"
    else
        log_info "Skipping $pkg (directory not found)"
    fi
done

log_success "Dotfiles setup complete!"
