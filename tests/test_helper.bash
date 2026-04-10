#!/usr/bin/env bats

# Test helper functions

# Setup function - runs before each test
setup() {
    # Ensure we're in the project directory
    cd "${BATS_TEST_DIRNAME}/.." || exit 1
}

# Teardown function - runs after each test
teardown() {
    if [ -n "${TEST_TMPDIR:-}" ]; then
        rm -rf "$TEST_TMPDIR"
    fi
    rm -rf /tmp/test-dotfiles-* 2>/dev/null || true
}

setup_isolated_env() {
    TEST_TMPDIR="$(mktemp -d)"
    TEST_HOME="$TEST_TMPDIR/home"
    TEST_BIN="$TEST_TMPDIR/bin"
    TEST_LOG="$TEST_TMPDIR/calls.log"

    mkdir -p "$TEST_HOME/.config" "$TEST_HOME/.local/bin" "$TEST_BIN"
    : > "$TEST_LOG"

    export HOME="$TEST_HOME"
    export TEST_BIN
    export TEST_LOG
    export PATH="$TEST_BIN:$PATH"
}

make_stub() {
    local name="$1"
    local body="$2"

    cat > "$TEST_BIN/$name" <<EOF
#!/bin/sh
set -eu
printf '%s\n' "\$0 \$*" >> "$TEST_LOG"
$body
EOF
    chmod +x "$TEST_BIN/$name"
}

assert_call_logged() {
    local expected="$1"
    grep -F "$expected" "$TEST_LOG" >/dev/null
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
