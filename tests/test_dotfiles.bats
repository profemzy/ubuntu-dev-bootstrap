#!/usr/bin/env bats

# Test suite for dotfiles handling (install-dotfiles.sh)
# These tests verify URL parameter handling and HTTPS cloning

load 'test_helper'

@test "dotfiles: --help not available (minimal script)" {
    # install-dotfiles.sh doesn't have --help, only --dotfiles-url
    run ./install-dotfiles.sh --help
    # Should fail since option is unknown
    [ "$status" -ne 0 ]
}

@test "dotfiles: accepts --dotfiles-url parameter" {
    # This test would need a mock or skip if already installed
    skip "Requires clean environment to test clone behavior"
}

@test "dotfiles: default URL is HTTPS not SSH" {
    # Verify the script contains HTTPS URL
    run grep -q "https://github.com/profemzy/dotfiles.git" ./install-dotfiles.sh
    [ "$status" -eq 0 ]
}

@test "dotfiles: does not contain SSH URL format" {
    # Verify SSH URL is removed
    run grep -q "git@github.com" ./install-dotfiles.sh
    [ "$status" -ne 0 ]
}

@test "dotfiles: custom URL is passed correctly" {
    # Simulate passing custom URL through install-all.sh
    run ./install-all.sh --dotfiles-url https://example.com/test.git --dry-run --profile frontend
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Dotfiles: https://example.com/test.git" ]]
}

@test "dotfiles: script validates URL parameter format" {
    # Missing URL should fail
    run ./install-dotfiles.sh --dotfiles-url
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a URL" ]]
}

@test "dotfiles: handles existing directory gracefully" {
    # If dotfiles dir exists, should skip clone
    skip "Requires test environment with existing dotfiles"
}

@test "dotfiles: updates remote URL if different" {
    skip "Requires test environment setup"
}

@test "dotfiles: reports helpful error on clone failure" {
    skip "Requires network failure simulation"
}