#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/mise/shims:/usr/local/go/bin:$PATH"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Flags
DRY_RUN=false
VERBOSE=false

# Components to skip
declare -a SKIP_COMPONENTS=()

# Track what would be/was installed
declare -a WILL_INSTALL=()
declare -a WILL_SKIP=()
declare -a INSTALLED=()
declare -a FAILED=()

# Cleanup function for trap
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo ""
        echo -e "${RED}==================================${NC}"
        echo -e "${RED}Installation failed!${NC}"
        echo -e "${RED}==================================${NC}"
        if [ ${#INSTALLED[@]} -gt 0 ]; then
            echo -e "${GREEN}Successfully installed before failure:${NC}"
            printf '  - %s\n' "${INSTALLED[@]}"
        fi
        if [ ${#FAILED[@]} -gt 0 ]; then
            echo -e "${RED}Failed components:${NC}"
            printf '  - %s\n' "${FAILED[@]}"
        fi
        echo ""
        echo "Check the error message above for details."
        echo "You can re-run this script after fixing the issue."
    fi
    exit $exit_code
}

trap cleanup EXIT

# Available components (for --skip validation)
AVAILABLE_COMPONENTS="zsh shelltools fastfetch uv rust golang mise nodejs ruby docker stow dotfiles devops zed shell"

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Pop!_OS Supplement Installation Script

OPTIONS:
    -n, --dry-run        Show what would be installed without making changes
    -s, --skip COMP      Skip component(s). Can be used multiple times or comma-separated
    -v, --verbose        Show detailed output during installation
    -h, --help           Show this help message

AVAILABLE COMPONENTS (for --skip):
    zsh         Zsh shell
    shelltools  Shell tools (starship, zoxide, fzf, nerd fonts)
    fastfetch   Fastfetch system info tool
    uv          Python uv package manager
    rust        Rust programming language
    golang      Go programming language
    mise        mise version manager
    nodejs      Node.js runtime
    ruby        Ruby runtime
    docker      Docker CE with compose plugin
    stow        GNU stow
    dotfiles    Dotfiles configuration
    devops      DevOps tools (kubectl, helm, terraform, etc.)
    zed         Configure Zed to allow emulated GPUs
    shell       Set Zsh as default shell

EXAMPLES:
    $(basename "$0")                          # Run full installation
    $(basename "$0") --dry-run                # Preview what would be installed
    $(basename "$0") --skip docker            # Skip Docker installation
    $(basename "$0") -s docker,ruby           # Skip multiple components
    $(basename "$0") -s docker -s devops      # Skip using multiple flags

EOF
    exit 0
}

# Validate component name
validate_component() {
    local comp=$1
    if [[ ! " $AVAILABLE_COMPONENTS " =~ " $comp " ]]; then
        log_error "Unknown component: $comp"
        echo "Available components: $AVAILABLE_COMPONENTS"
        exit 1
    fi
}

# Check if component should be skipped
should_skip() {
    local comp=$1
    for skip in "${SKIP_COMPONENTS[@]}"; do
        if [[ "$skip" == "$comp" ]]; then
            return 0
        fi
    done
    return 1
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -s|--skip)
                if [[ -z "${2:-}" ]]; then
                    log_error "--skip requires a component name"
                    exit 1
                fi
                # Handle comma-separated values
                IFS=',' read -ra COMPS <<< "$2"
                for comp in "${COMPS[@]}"; do
                    validate_component "$comp"
                    SKIP_COMPONENTS+=("$comp")
                done
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}"
                usage
                ;;
        esac
    done
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[$1]${NC} $2"
}

log_dry_run() {
    echo -e "${YELLOW}[DRY-RUN]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

font_installed() {
    grep -Eiq 'JetBrainsMono.*Nerd|Nerd.*JetBrainsMono' < <(fc-list)
}

# Function to run script only if needed
run_if_needed() {
    local script="$1"
    local check_cmd="$2"
    local step_num="$3"
    local step_name="$4"
    local component_id="$5"

    log_step "$step_num" "$step_name..."

    # Check if component should be skipped
    if should_skip "$component_id"; then
        log_warning "Skipped by user (--skip $component_id)"
        WILL_SKIP+=("$step_name (skipped)")
        echo ""
        return 0
    fi

    local needs_install=true
    if [ -n "$check_cmd" ] && eval "$check_cmd" 2>/dev/null; then
        needs_install=false
    fi

    if [ "$needs_install" = false ]; then
        log_success "Already installed, skipping"
        WILL_SKIP+=("$step_name")
    else
        if [ "$DRY_RUN" = true ]; then
            log_dry_run "Would run: ./$script"
            WILL_INSTALL+=("$step_name")
        else
            if [ "$VERBOSE" = true ]; then
                log_info "Running: ./$script"
            fi

            # Split script into command and arguments
            read -ra script_args <<< "$script"
            if ! "${SCRIPT_DIR}/${script_args[0]}" "${script_args[@]:1}"; then
                log_error "Failed to install: $step_name"
                FAILED+=("$step_name")
                return 1
            fi

            INSTALLED+=("$step_name")
            log_success "$step_name installed successfully"
        fi
    fi
    echo ""
}

# Main installation
main() {
    parse_args "$@"

    echo "==================================="
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}Pop!_OS Supplement - DRY RUN${NC}"
        echo "No changes will be made"
    else
        echo "Pop!_OS Supplement Installation"
    fi
    echo "==================================="
    echo ""

    # Verify we're in the correct directory
    if [ ! -f "${SCRIPT_DIR}/install-zsh.sh" ]; then
        log_error "Cannot find installation scripts. Please run from the popos-supplements directory."
        exit 1
    fi

    # Check prerequisites
    if ! command_exists apt; then
        log_error "apt is not available. This script is designed for Pop!_OS/Ubuntu."
        exit 1
    fi

    if ! command_exists git; then
        log_error "git is not installed. Please install git first."
        exit 1
    fi

    # Install all packages in order
    run_if_needed "install-zsh.sh" "command_exists zsh" "1/15" "Zsh" "zsh"

    run_if_needed "install-shell-tools.sh" "command_exists starship && command_exists zoxide && command_exists fzf && font_installed" "2/15" "Shell tools (starship, zoxide, fzf, fonts)" "shelltools"

    run_if_needed "install-fastfetch.sh" "command_exists fastfetch" "3/15" "Fastfetch" "fastfetch"

    run_if_needed "install-uv.sh" "command_exists uv" "4/15" "Python uv" "uv"

    run_if_needed "install-rust.sh" "command_exists rustc" "5/15" "Rust" "rust"

    run_if_needed "install-golang.sh" "command_exists go" "6/15" "Go" "golang"

    run_if_needed "install-mise.sh" "command_exists mise" "7/15" "mise (version manager)" "mise"

    run_if_needed "install-nodejs.sh" "command_exists node" "8/15" "Node.js" "nodejs"

    run_if_needed "install-ruby.sh" "command_exists ruby" "9/15" "Ruby" "ruby"

    run_if_needed "install-docker.sh" "command_exists docker" "10/15" "Docker CE" "docker"

    run_if_needed "install-stow.sh" "command_exists stow" "11/15" "stow" "stow"

    run_if_needed "install-dotfiles.sh" "[ -d ~/dotfiles ] && [ -L ~/.zshrc ] && [ -L ~/.config/nvim ] && [ -L ~/.config/starship.toml ] && [ -f ~/.zprofile ]" "12/15" "Dotfiles" "dotfiles"

    run_if_needed "install-devops-tools.sh" "command_exists kubectl && command_exists kubectx && command_exists kubens && command_exists helm && command_exists k9s && command_exists stern && command_exists argocd && command_exists flux && command_exists terraform && command_exists ansible && command_exists aws && command_exists gcloud && command_exists az && command_exists gh && command_exists yq && command_exists http" "13/15" "DevOps tools" "devops"

    run_if_needed "configure-zed.sh" "[ -f ~/.config/environment.d/zed.conf ] && grep -qx 'ZED_ALLOW_EMULATED_GPU=1' ~/.config/environment.d/zed.conf" "14/15" "Configure Zed emulated GPU override" "zed"

    run_if_needed "set-shell.sh --non-interactive" "[ \"\$(getent passwd \"$USER\" | cut -d: -f7)\" = \"\$(command -v zsh 2>/dev/null || echo /nonexistent)\" ]" "15/15" "Set default shell" "shell"
    # Summary
    echo "==================================="
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}DRY RUN SUMMARY${NC}"
        echo "==================================="
        echo ""
        if [ ${#WILL_INSTALL[@]} -gt 0 ]; then
            echo -e "${BLUE}Would install:${NC}"
            printf '  - %s\n' "${WILL_INSTALL[@]}"
            echo ""
        fi
        if [ ${#WILL_SKIP[@]} -gt 0 ]; then
            echo -e "${GREEN}Already installed (would skip):${NC}"
            printf '  - %s\n' "${WILL_SKIP[@]}"
            echo ""
        fi
        echo "Run without --dry-run to perform the installation."
    else
        echo -e "${GREEN}Installation complete!${NC}"
        echo "==================================="
        echo ""
        if [ ${#INSTALLED[@]} -gt 0 ]; then
            echo -e "${GREEN}Newly installed:${NC}"
            printf '  - %s\n' "${INSTALLED[@]}"
            echo ""
        fi
        if [ ${#WILL_SKIP[@]} -gt 0 ]; then
            echo -e "${BLUE}Already installed:${NC}"
            printf '  - %s\n' "${WILL_SKIP[@]}"
            echo ""
        fi
        echo "Please log out and log back in for all changes to take effect."
    fi
}

main "$@"
