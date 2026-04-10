#!/usr/bin/env bats

# Test helper functions

# Setup function - runs before each test
setup() {
    # Ensure we're in the project directory
    cd "${BATS_TEST_DIRNAME}/.." || exit 1
}

# Teardown function - runs after each test
teardown() {
    # Clean up any test artifacts
    rm -rf /tmp/test-dotfiles-* 2>/dev/null || true
}

# Helper to check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Helper to get current installed components
get_installed_components() {
    local components=""
    command_exists zsh && components+="zsh "
    command_exists starship && components+="starship "
    command_exists mise && components+="mise "
    echo "$components"
}