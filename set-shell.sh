#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check if we're in interactive mode
INTERACTIVE=true
if [[ "${1:-}" == "--non-interactive" ]]; then
    INTERACTIVE=false
    shift
fi

# Track success
SUCCESS=false

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ] && [ "$SUCCESS" != true ]; then
        log_error "Shell configuration failed."
        echo ""
        if [ "$INTERACTIVE" = false ]; then
            log_warning "This script was run in non-interactive mode."
            log_warning "Please run './set-shell.sh' interactively to fix the shell."
        fi
    fi
    exit $exit_code
}

trap cleanup EXIT

# Check if zsh is installed
if ! command -v zsh &>/dev/null; then
    log_error "Zsh is not installed. Please run ./install-zsh.sh first."
    exit 1
fi

# Get the path to zsh
ZSH_PATH=$(which zsh)
CURRENT_SHELL=$(echo "$SHELL")

log_info "Current shell: $CURRENT_SHELL"
log_info "Target shell: $ZSH_PATH"

# Check if zsh is already the default shell
if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    log_success "Zsh is already your default shell"
    SUCCESS=true
    exit 0
fi

# Add zsh to /etc/shells if not already there
if ! grep -q "^$ZSH_PATH$" /etc/shells 2>/dev/null; then
    log_info "Adding zsh to /etc/shells..."
    if echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null; then
        log_success "Added zsh to /etc/shells"
    else
        log_error "Failed to add zsh to /etc/shells"
        exit 1
    fi
else
    log_success "zsh is already in /etc/shells"
fi

# Interactive mode
if [ "$INTERACTIVE" = true ]; then
    echo ""
    log_info "To change your default shell to zsh, you need to enter your password."
    log_warning "This will prompt for your password..."
    echo ""

    # Run chsh interactively so it can prompt for password
    if chsh -s "$ZSH_PATH"; then
        SUCCESS=true
        log_success "Default shell changed to zsh"
        echo ""
        echo "==================================="
        echo -e "${GREEN}IMPORTANT:${NC}"
        echo "Please log out and log back in for the change to take effect"
        echo "==================================="
        echo ""

        # Verify the change was applied
        if grep "^$USER:" /etc/passwd | cut -d: -f7 | grep -q "zsh"; then
            log_success "Shell change confirmed in /etc/passwd"
        else
            log_warning "Shell change may not have taken effect. Please verify manually."
        fi
    else
        log_error "Failed to change shell with chsh"
        echo ""
        log_warning "Alternative: You can try running with sudo:"
        echo -e "${YELLOW}    sudo chsh -s $ZSH_PATH $USER${NC}"
        echo ""
        exit 1
    fi
else
    # Non-interactive mode - just show instructions
    log_warning "Cannot change shell in non-interactive mode."
    echo ""
    log_info "Please run the following command manually:"
    echo ""
    echo -e "${YELLOW}    chsh -s $ZSH_PATH${NC}"
    echo ""
    log_warning "Enter your password when prompted."
    log_warning "After running the command, log out and log back in."
    echo ""

    # Don't exit with error code in non-interactive mode
    # This allows install-all.sh to continue
    SUCCESS=true
    log_info "Shell change instructions provided. Please run manually."
fi