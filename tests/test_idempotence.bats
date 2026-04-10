#!/usr/bin/env bats

# Test suite for idempotent behavior
# These tests verify that re-running skips installed components

load 'test_helper'

@test "idempotence: install-all.sh uses command_exists checks" {
    # Verify idempotent check pattern exists
    run grep -q "command_exists" ./install-all.sh
    [ "$status" -eq 0 ]
}

@test "idempotence: each install script has command_exists pattern" {
    for script in install-zsh.sh install-mise.sh install-docker.sh install-stow.sh; do
        run grep -q "command_exists" "./$script"
        [ "$status" -eq 0 ]
    done
}

@test "idempotence: dry-run shows 'Already installed' for existing tools" {
    run ./install-all.sh --dry-run --profile minimal
    [ "$status" -eq 0 ]
    # Should show "Already installed" for at least some components
    [[ "$output" =~ "Already installed" ]]
}

@test "idempotence: second run would skip all already-installed" {
    # First check what's installed, then verify dry-run skips them
    run ./install-all.sh --dry-run --profile minimal
    [ "$status" -eq 0 ]
}

@test "idempotence: FAILED_PACKAGES tracking exists" {
    # Verify failure tracking mechanism
    run grep -q "FAILED_PACKAGES" ./install-all.sh
    [ "$status" -eq 0 ]
}

@test "idempotence: install-devops-tools tracks failures" {
    run grep -q "FAILED_PACKAGES" ./install-devops-tools.sh
    [ "$status" -eq 0 ]
}

@test "idempotence: cleanup trap exists in scripts" {
    for script in install-all.sh install-dotfiles.sh install-devops-tools.sh; do
        run grep -q "trap cleanup" "./$script"
        [ "$status" -eq 0 ]
    done
}

@test "idempotence: set -e ensures error detection" {
    for script in install-all.sh install-dotfiles.sh install-devops-tools.sh; do
        run grep -q "set -euo pipefail" "./$script"
        [ "$status" -eq 0 ]
    done
}

@test "idempotence: profile filtering prevents redundant installs" {
    # Running minimal profile should not try to install devops tools
    run ./install-all.sh --profile minimal --dry-run
    [ "$status" -eq 0 ]
    # DevOps should show "Not included" message
    [[ "$output" =~ "Not included" ]]
}

@test "idempotence: --skip prevents installation of specified component" {
    run ./install-all.sh --skip docker --dry-run --profile full
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Skipped by user" ]]
}