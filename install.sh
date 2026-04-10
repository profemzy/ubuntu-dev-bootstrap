#!/bin/bash

set -euo pipefail

# ============================================================================
# ubuntu-dev-bootstrap - Bootstrap Installer
# ============================================================================
# This is the curl-accessible entry point for ubuntu-dev-bootstrap.
# It downloads the repository to a temporary directory, prompts the user
# for configuration (in interactive mode), runs the installer, and cleans up.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/profemzy/ubuntu-dev-bootstrap/master/install.sh | bash
#   curl -sSL ... | bash -s -- --profile devops --non-interactive
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default values
PROFILE="full"
DOTFILES_URL="https://github.com/profemzy/dotfiles.git"
NON_INTERACTIVE=false
DRY_RUN=false
VERBOSE=false

# Temporary directory
TEMP_DIR=""
REPO_URL="https://github.com/profemzy/ubuntu-dev-bootstrap.git"
REPO_BRANCH="master"

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_step() { echo -e "${CYAN}[$1]${NC} $2"; }

# Cleanup function
cleanup() {
    local exit_code=$?

    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        if [ "$VERBOSE" = true ]; then
            log_info "Cleaning up temporary directory: $TEMP_DIR"
        fi
        rm -rf "$TEMP_DIR"
    fi

    if [ $exit_code -ne 0 ]; then
        echo ""
        log_error "Installation failed. Check the output above for details."
    fi

    exit $exit_code
}

trap cleanup EXIT

# Usage information
usage() {
    cat << EOF
Usage: install.sh [OPTIONS]

Ubuntu Developer Bootstrap - Automated development environment setup

OPTIONS:
    -p, --profile PROFILE     Installation profile (minimal, frontend, devops, full)
    -d, --dotfiles URL        Custom dotfiles repository URL
    -n, --non-interactive     Skip all prompts, use defaults
    --dry-run                 Preview what would be installed
    -v, --verbose             Show detailed output
    -h, --help                Show this help message

PROFILES:
    minimal     Shell tools, mise, stow (base layer)
    frontend    minimal + Node.js, dotfiles
    devops      minimal + Docker, kubectl, helm, terraform, cloud CLIs
    full        frontend + devops + Ruby, Rust, Go, uv, fastfetch

EXAMPLES:
    curl -sSL https://raw.githubusercontent.com/profemzy/ubuntu-dev-bootstrap/master/install.sh | bash
    curl -sSL ... | bash -s -- --profile devops
    curl -sSL ... | bash -s -- --profile minimal --non-interactive
    curl -sSL ... | bash -s -- --dry-run

EOF
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--profile)
                if [[ -z "${2:-}" ]]; then
                    log_error "--profile requires a profile name"
                    exit 1
                fi
                PROFILE="$2"
                shift 2
                ;;
            -d|--dotfiles)
                if [[ -z "${2:-}" ]]; then
                    log_error "--dotfiles requires a URL"
                    exit 1
                fi
                DOTFILES_URL="$2"
                shift 2
                ;;
            -n|--non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Validate profile name
validate_profile() {
    local profile="$1"
    local valid_profiles="minimal frontend devops full"

    if [[ ! " $valid_profiles " =~ " $profile " ]]; then
        log_error "Invalid profile: $profile"
        echo "Valid profiles: $valid_profiles"
        exit 1
    fi
}

# Check if running interactively (stdin is not a tty)
# When piped via curl | bash, stdin is the script content, not the terminal
is_piped() {
    [ ! -t 0 ]
}

# Prompt user for profile selection (interactive mode)
prompt_profile() {
    echo ""
    echo "Select an installation profile:"
    echo ""
    echo "  1) minimal     - Shell tools, mise, stow (base layer)"
    echo "  2) frontend    - minimal + Node.js, dotfiles"
    echo "  3) devops      - minimal + Docker, kubectl, helm, terraform, cloud CLIs"
    echo "  4) full        - frontend + devops + Ruby, Rust, Go, uv, fastfetch"
    echo ""
    echo -n "Enter choice [1-4] (default: 4): "

    # Read from /dev/tty when piped, otherwise read from stdin
    if is_piped; then
        read -r choice < /dev/tty
    else
        read -r choice
    fi

    case "$choice" in
        1) PROFILE="minimal" ;;
        2) PROFILE="frontend" ;;
        3) PROFILE="devops" ;;
        4|"") PROFILE="full" ;;
        *) log_warning "Invalid choice, using default (full)"; PROFILE="full" ;;
    esac

    log_info "Selected profile: $PROFILE"
}

# Prompt user for dotfiles URL (interactive mode)
prompt_dotfiles() {
    echo ""
    echo "Dotfiles configuration:"
    echo ""
    echo "  Default: https://github.com/profemzy/dotfiles.git"
    echo ""
    echo "Enter a custom dotfiles URL (or press Enter for default):"
    echo -n "> "

    # Read from /dev/tty when piped, otherwise read from stdin
    if is_piped; then
        read -r custom_url < /dev/tty
    else
        read -r custom_url
    fi

    if [[ -n "$custom_url" ]]; then
        DOTFILES_URL="$custom_url"
        log_info "Using custom dotfiles: $DOTFILES_URL"
    else
        log_info "Using default dotfiles: $DOTFILES_URL"
    fi
}

# Download repository to temporary directory
download_repo() {
    TEMP_DIR="/tmp/ubuntu-dev-bootstrap-$(date +%Y%m%d%H%M%S)"

    log_step "1" "Downloading ubuntu-dev-bootstrap..."

    if [ "$DRY_RUN" = true ]; then
        log_warning "[DRY-RUN] Would clone repository to: $TEMP_DIR"
        return 0
    fi

    mkdir -p "$TEMP_DIR"

    if ! git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" "$TEMP_DIR" 2>&1; then
        log_error "Failed to clone repository"
        log_info "Ensure you have internet access and git installed"
        exit 1
    fi

    log_success "Repository downloaded to: $TEMP_DIR"
}

# Run the installer
run_installer() {
    log_step "2" "Running installation..."

    if [ "$DRY_RUN" = true ]; then
        log_warning "[DRY-RUN] Would run: ./install-all.sh --profile $PROFILE --dotfiles $DOTFILES_URL"
        echo ""
        echo "Components that would be installed for '$PROFILE' profile:"
        case "$PROFILE" in
            minimal)
                echo "  - zsh, shelltools, stow, mise"
                ;;
            frontend)
                echo "  - minimal + nodejs, dotfiles"
                ;;
            devops)
                echo "  - minimal + docker, kubectl, helm, terraform, ansible"
                echo "  - cloud CLIs: aws, gcloud, az"
                echo "  - k9s, argocd, flux, stern, yq, httpie"
                ;;
            full)
                echo "  - frontend + devops + ruby, rust, golang, uv, fastfetch, zed"
                ;;
        esac
        return 0
    fi

    cd "$TEMP_DIR"

    # Build command with flags
    local cmd="./install-all.sh --profile $PROFILE --dotfiles-url $DOTFILES_URL"

    if [ "$NON_INTERACTIVE" = true ]; then
        cmd="$cmd --non-interactive"
    fi

    if [ "$VERBOSE" = true ]; then
        cmd="$cmd --verbose"
    fi

    if [ "$VERBOSE" = true ]; then
        log_info "Running: $cmd"
    fi

    if ! bash "$cmd"; then
        log_error "Installation failed"
        exit 1
    fi
}

# Print next steps
print_next_steps() {
    if [ "$DRY_RUN" = true ]; then
        echo ""
        echo "==================================="
        echo -e "${YELLOW}DRY RUN COMPLETE${NC}"
        echo "==================================="
        echo ""
        echo "Run without --dry-run to perform the actual installation."
        return 0
    fi

    echo ""
    echo "==================================="
    echo -e "${GREEN}INSTALLATION COMPLETE${NC}"
    echo "==================================="
    echo ""
    echo "Next steps:"
    echo "  1. Log out and log back in for shell changes to take effect"
    echo "  2. Configure cloud CLI authentication:"
    echo "     - AWS:        aws configure"
    echo "     - Google:     gcloud init"
    echo "     - Azure:      az login"
    echo "     - GitHub:     gh auth login"
    echo "  3. Configure Kubernetes:"
    echo "     - kubectl:    kubectl config view"
    echo "     - ArgoCD:     argocd login <server>"
    echo "     - Flux:       flux check --pre"
    echo ""
}

# Main function
main() {
    # Parse arguments passed via curl | bash -s --
    parse_args "$@"

    # Validate profile
    validate_profile "$PROFILE"

    echo "==================================="
    echo -e "${CYAN}Ubuntu Developer Bootstrap${NC}"
    echo "==================================="
    echo ""

    # Interactive prompts (if not non-interactive)
    if [ "$NON_INTERACTIVE" = false ] && [ "$DRY_RUN" = false ]; then
        prompt_profile
        prompt_dotfiles
    else
        log_info "Profile: $PROFILE"
        log_info "Dotfiles: $DOTFILES_URL"
        if [ "$NON_INTERACTIVE" = true ]; then
            log_info "Mode: non-interactive"
        fi
        if [ "$DRY_RUN" = true ]; then
            log_info "Mode: dry-run"
        fi
    fi

    # Download and run
    download_repo
    run_installer

    # Print next steps
    print_next_steps
}

main "$@"