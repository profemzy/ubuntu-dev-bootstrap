#!/usr/bin/env bats

# Test suite for idempotent behavior
# These tests verify that re-running skips installed components

load 'test_helper'

@test "idempotence: dry-run marks stubbed installed zsh as already installed" {
    setup_isolated_env
    make_stub zsh 'exit 0'

    run ./install-all.sh --dry-run --profile minimal

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Zsh..." ]]
    [[ "$output" =~ "Already installed, skipping" ]]
}

@test "idempotence: dry-run summary reports zsh as skipped when installed" {
    setup_isolated_env
    make_stub zsh 'exit 0'

    run ./install-all.sh --dry-run --profile minimal

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Already installed (would skip):" ]]
    [[ "$output" =~ "  - Zsh" ]]
}

@test "idempotence: profile filtering prevents redundant installs" {
    run ./install-all.sh --profile minimal --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DevOps tools..." ]]
    [[ "$output" =~ "Not included in 'minimal' profile" ]]
}

@test "idempotence: --skip prevents installation of specified component" {
    run ./install-all.sh --skip docker --dry-run --profile full
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Skipped by user (--skip docker)" ]]
}
